module subtractor_4bit_axi_lite (
    // Clock and reset
    input wire aclk,
    input wire aresetn,
    
    // Write address channel
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write data channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write response channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read address channel
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read data channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);

    // Internal registers
    reg [3:0] a_reg, b_reg;
    reg [3:0] diff_reg;
    reg valid_reg;
    
    // Address decoding
    localparam ADDR_A = 4'h0;
    localparam ADDR_B = 4'h4;
    localparam ADDR_DIFF = 4'h8;
    
    // Write state machine
    reg [1:0] write_state;
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    // Read state machine
    reg [1:0] read_state;
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    // Write state machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= WRITE_IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            a_reg <= 4'b0;
            b_reg <= 4'b0;
            valid_reg <= 1'b0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b0;
                    
                    if (s_axil_awvalid) begin
                        write_state <= WRITE_ADDR;
                        s_axil_awready <= 1'b0;
                    end
                end
                
                WRITE_ADDR: begin
                    s_axil_wready <= 1'b1;
                    
                    if (s_axil_wvalid) begin
                        write_state <= WRITE_RESP;
                        s_axil_wready <= 1'b0;
                        
                        // Write to appropriate register based on address
                        case (s_axil_awaddr[3:0])
                            ADDR_A: begin
                                a_reg <= s_axil_wdata[3:0];
                                valid_reg <= 1'b1;
                            end
                            ADDR_B: begin
                                b_reg <= s_axil_wdata[3:0];
                                valid_reg <= 1'b1;
                            end
                            default: begin
                                s_axil_bresp <= 2'b10; // SLVERR
                            end
                        endcase
                    end
                end
                
                WRITE_RESP: begin
                    s_axil_bvalid <= 1'b1;
                    
                    if (s_axil_bready) begin
                        write_state <= WRITE_IDLE;
                        s_axil_bvalid <= 1'b0;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // Optimized subtraction computation using carry-lookahead logic
    wire [3:0] b_comp = ~b_reg;
    wire [3:0] sum = a_reg + b_comp + 1'b1;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            diff_reg <= 4'b0;
        end else if (valid_reg) begin
            diff_reg <= sum;
        end
    end
    
    // Read state machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= READ_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'b0;
            s_axil_rresp <= 2'b00;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    s_axil_arready <= 1'b1;
                    s_axil_rvalid <= 1'b0;
                    
                    if (s_axil_arvalid) begin
                        read_state <= READ_ADDR;
                        s_axil_arready <= 1'b0;
                    end
                end
                
                READ_ADDR: begin
                    read_state <= READ_DATA;
                end
                
                READ_DATA: begin
                    s_axil_rvalid <= 1'b1;
                    
                    // Read from appropriate register based on address
                    case (s_axil_araddr[3:0])
                        ADDR_A: s_axil_rdata <= {28'b0, a_reg};
                        ADDR_B: s_axil_rdata <= {28'b0, b_reg};
                        ADDR_DIFF: s_axil_rdata <= {28'b0, diff_reg};
                        default: begin
                            s_axil_rdata <= 32'b0;
                            s_axil_rresp <= 2'b10; // SLVERR
                        end
                    endcase
                    
                    if (s_axil_rready) begin
                        read_state <= READ_IDLE;
                        s_axil_rvalid <= 1'b0;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end

endmodule