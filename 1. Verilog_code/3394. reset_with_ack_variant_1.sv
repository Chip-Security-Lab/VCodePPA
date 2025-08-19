//SystemVerilog
// SystemVerilog
module reset_with_ack(
    input  wire        clk,
    input  wire        aresetn,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input  wire [31:0] s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    
    // Write Data Channel
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    
    // Write Response Channel
    output wire [1:0]  s_axil_bresp,
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,
    
    // Read Address Channel
    input  wire [31:0] s_axil_araddr,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    
    // Read Data Channel
    output wire [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready,
    
    // External Interface
    input  wire [3:0]  ack_signals,
    output wire [3:0]  reset_out
);

    // AXI-Lite response codes
    localparam RESP_OKAY   = 2'b00;
    localparam RESP_SLVERR = 2'b10;
    
    // Register addresses
    localparam ADDR_RESET_REQ     = 4'h0;  // 0x00: Reset request register
    localparam ADDR_RESET_STATUS  = 4'h4;  // 0x04: Reset status register
    localparam ADDR_RESET_ACK     = 4'h8;  // 0x08: Reset acknowledgment register
    localparam ADDR_RESET_OUT     = 4'hC;  // 0x0C: Reset output register
    
    // Internal registers
    reg        reset_req;
    reg [3:0]  reset_out_reg;
    reg        reset_complete;
    
    // AXI4-Lite interface control registers
    reg        awready;
    reg        wready;
    reg        bvalid;
    reg [1:0]  bresp;
    reg        arready;
    reg        rvalid;
    reg [1:0]  rresp;
    reg [31:0] rdata;
    
    // Write address channel handshake
    assign s_axil_awready = awready;
    
    // Write data channel handshake
    assign s_axil_wready = wready;
    
    // Write response channel
    assign s_axil_bvalid = bvalid;
    assign s_axil_bresp = bresp;
    
    // Read address channel handshake
    assign s_axil_arready = arready;
    
    // Read data channel
    assign s_axil_rvalid = rvalid;
    assign s_axil_rresp = rresp;
    assign s_axil_rdata = rdata;
    
    // Reset logic pipeline stages
    reg        reset_req_pipe1;
    reg [3:0]  ack_signals_pipe1;
    reg        reset_req_pipe2;
    reg [3:0]  ack_signals_pipe2;
    reg        all_acks_received;
    reg [3:0]  reset_ctrl;
    reg        reset_status;
    
    assign reset_out = reset_out_reg;
    
    // ===== AXI-Lite Write Transaction Logic =====
    reg [1:0] write_state;
    reg [31:0] write_addr;
    
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= WRITE_IDLE;
            awready <= 1'b0;
            wready <= 1'b0;
            bvalid <= 1'b0;
            bresp <= RESP_OKAY;
            write_addr <= 32'h0;
            reset_req <= 1'b0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    awready <= 1'b1;
                    wready <= 1'b0;
                    bvalid <= 1'b0;
                    
                    if (s_axil_awvalid && awready) begin
                        write_addr <= s_axil_awaddr;
                        awready <= 1'b0;
                        wready <= 1'b1;
                        write_state <= WRITE_ADDR;
                    end
                end
                
                WRITE_ADDR: begin
                    if (s_axil_wvalid && wready) begin
                        wready <= 1'b0;
                        bvalid <= 1'b1;
                        
                        // Process write data based on address
                        case (write_addr[3:0])
                            ADDR_RESET_REQ: begin
                                if (s_axil_wstrb[0]) begin
                                    reset_req <= s_axil_wdata[0];
                                end
                                bresp <= RESP_OKAY;
                            end
                            default: begin
                                // Address not recognized
                                bresp <= RESP_SLVERR;
                            end
                        endcase
                        
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready && bvalid) begin
                        bvalid <= 1'b0;
                        awready <= 1'b1;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: begin
                    write_state <= WRITE_IDLE;
                end
            endcase
        end
    end
    
    // ===== AXI-Lite Read Transaction Logic =====
    reg [1:0] read_state;
    reg [31:0] read_addr;
    
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= READ_IDLE;
            arready <= 1'b0;
            rvalid <= 1'b0;
            rresp <= RESP_OKAY;
            rdata <= 32'h0;
            read_addr <= 32'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    arready <= 1'b1;
                    rvalid <= 1'b0;
                    
                    if (s_axil_arvalid && arready) begin
                        read_addr <= s_axil_araddr;
                        arready <= 1'b0;
                        read_state <= READ_ADDR;
                    end
                end
                
                READ_ADDR: begin
                    // Prepare read data based on address
                    case (read_addr[3:0])
                        ADDR_RESET_REQ: begin
                            rdata <= {31'h0, reset_req};
                            rresp <= RESP_OKAY;
                        end
                        ADDR_RESET_STATUS: begin
                            rdata <= {31'h0, reset_complete};
                            rresp <= RESP_OKAY;
                        end
                        ADDR_RESET_ACK: begin
                            rdata <= {28'h0, ack_signals};
                            rresp <= RESP_OKAY;
                        end
                        ADDR_RESET_OUT: begin
                            rdata <= {28'h0, reset_out_reg};
                            rresp <= RESP_OKAY;
                        end
                        default: begin
                            rdata <= 32'h0;
                            rresp <= RESP_SLVERR;
                        end
                    endcase
                    
                    rvalid <= 1'b1;
                    read_state <= READ_DATA;
                end
                
                READ_DATA: begin
                    if (s_axil_rready && rvalid) begin
                        rvalid <= 1'b0;
                        arready <= 1'b1;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: begin
                    read_state <= READ_IDLE;
                end
            endcase
        end
    end
    
    // ===== Original Reset Controller Logic =====
    // Stage 1: Input Capture
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            reset_req_pipe1 <= 1'b0;
            ack_signals_pipe1 <= 4'h0;
        end else begin
            reset_req_pipe1 <= reset_req;
            ack_signals_pipe1 <= ack_signals;
        end
    end

    // Stage 2: Status Detection
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            reset_req_pipe2 <= 1'b0;
            ack_signals_pipe2 <= 4'h0;
            all_acks_received <= 1'b0;
        end else begin
            reset_req_pipe2 <= reset_req_pipe1;
            ack_signals_pipe2 <= ack_signals_pipe1;
            all_acks_received <= (ack_signals_pipe1 == 4'hF);
        end
    end

    // Stage 3: Control Logic
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            reset_ctrl <= 4'h0;
            reset_status <= 1'b0;
        end else begin
            if (reset_req_pipe2) begin
                reset_ctrl <= 4'hF;        // Assert all reset signals
                reset_status <= 1'b0;      // Reset not complete
            end else if (all_acks_received) begin
                reset_ctrl <= 4'h0;        // De-assert all reset signals
                reset_status <= 1'b1;      // Reset complete
            end
        end
    end

    // Stage 4: Output Registration
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            reset_out_reg <= 4'h0;
            reset_complete <= 1'b0;
        end else begin
            reset_out_reg <= reset_ctrl;
            reset_complete <= reset_status;
        end
    end

endmodule