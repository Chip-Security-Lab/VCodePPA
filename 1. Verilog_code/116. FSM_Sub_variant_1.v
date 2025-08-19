module FSM_Sub (
    // AXI4-Lite Interface
    input wire ACLK,
    input wire ARESETn,
    
    // Write Address Channel
    input wire [31:0] AWADDR,
    input wire AWVALID,
    output reg AWREADY,
    
    // Write Data Channel
    input wire [31:0] WDATA,
    input wire [3:0] WSTRB,
    input wire WVALID,
    output reg WREADY,
    
    // Write Response Channel
    output reg [1:0] BRESP,
    output reg BVALID,
    input wire BREADY,
    
    // Read Address Channel
    input wire [31:0] ARADDR,
    input wire ARVALID,
    output reg ARREADY,
    
    // Read Data Channel
    output reg [31:0] RDATA,
    output reg [1:0] RRESP,
    output reg RVALID,
    input wire RREADY
);

    // Internal registers
    reg [7:0] reg_A;
    reg [7:0] reg_B;
    reg [7:0] reg_res;
    reg reg_done;
    
    // Write FSM states - one-hot encoding for better timing
    localparam WRITE_IDLE = 3'b001;
    localparam WRITE_DATA = 3'b010;
    localparam WRITE_RESP = 3'b100;
    reg [2:0] write_state;
    
    // Read FSM states - one-hot encoding for better timing
    localparam READ_IDLE = 2'b01;
    localparam READ_DATA = 2'b10;
    reg [1:0] read_state;
    
    // Address decoding - pre-computed for better timing
    wire addr_is_reg_A = (AWADDR[3:0] == 4'h0);
    wire addr_is_reg_B = (AWADDR[3:0] == 4'h4);
    
    wire read_addr_is_reg_A = (ARADDR[3:0] == 4'h0);
    wire read_addr_is_reg_B = (ARADDR[3:0] == 4'h4);
    wire read_addr_is_reg_res = (ARADDR[3:0] == 4'h8);
    wire read_addr_is_reg_done = (ARADDR[3:0] == 4'hC);
    
    // Write FSM - optimized with one-hot encoding
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            write_state <= WRITE_IDLE;
            AWREADY <= 1'b1;
            WREADY <= 1'b0;
            BVALID <= 1'b0;
            BRESP <= 2'b00;
        end else begin
            case (1'b1) // Priority encoder style for one-hot states
                write_state[0]: begin // WRITE_IDLE
                    if (AWVALID && AWREADY) begin
                        AWREADY <= 1'b0;
                        WREADY <= 1'b1;
                        write_state <= WRITE_DATA;
                    end
                end
                write_state[1]: begin // WRITE_DATA
                    if (WVALID && WREADY) begin
                        WREADY <= 1'b0;
                        BVALID <= 1'b1;
                        write_state <= WRITE_RESP;
                        
                        if (addr_is_reg_A)
                            reg_A <= WDATA[7:0];
                        else if (addr_is_reg_B)
                            reg_B <= WDATA[7:0];
                    end
                end
                write_state[2]: begin // WRITE_RESP
                    if (BREADY) begin
                        BVALID <= 1'b0;
                        AWREADY <= 1'b1;
                        write_state <= WRITE_IDLE;
                    end
                end
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // Read FSM - optimized with one-hot encoding
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            read_state <= READ_IDLE;
            ARREADY <= 1'b1;
            RVALID <= 1'b0;
            RRESP <= 2'b00;
        end else begin
            case (1'b1) // Priority encoder style for one-hot states
                read_state[0]: begin // READ_IDLE
                    if (ARVALID && ARREADY) begin
                        ARREADY <= 1'b0;
                        RVALID <= 1'b1;
                        read_state <= READ_DATA;
                        
                        if (read_addr_is_reg_A)
                            RDATA <= {24'h0, reg_A};
                        else if (read_addr_is_reg_B)
                            RDATA <= {24'h0, reg_B};
                        else if (read_addr_is_reg_res)
                            RDATA <= {24'h0, reg_res};
                        else if (read_addr_is_reg_done)
                            RDATA <= {31'h0, reg_done};
                    end
                end
                read_state[1]: begin // READ_DATA
                    if (RREADY) begin
                        RVALID <= 1'b0;
                        ARREADY <= 1'b1;
                        read_state <= READ_IDLE;
                    end
                end
                default: read_state <= READ_IDLE;
            endcase
        end
    end
    
    // Core logic - optimized with direct assignment
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            reg_res <= 8'h0;
            reg_done <= 1'b0;
        end else begin
            reg_res <= reg_A - reg_B; // Direct subtraction
            reg_done <= 1'b1;
        end
    end

endmodule