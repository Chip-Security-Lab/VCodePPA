//SystemVerilog
module Gen_NAND_AXI4Lite(
    // Global Signals
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input  wire [7:0]  s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input  wire [7:0]  s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    // Register Addresses
    localparam REG_VEC_A     = 8'h00;  // Input vector A address
    localparam REG_VEC_B     = 8'h04;  // Input vector B address
    localparam REG_RESULT    = 8'h08;  // Output result address
    localparam REG_CONTROL   = 8'h0C;  // Control register address
    
    // AXI Response Codes
    localparam RESP_OKAY     = 2'b00;
    localparam RESP_SLVERR   = 2'b10;
    
    // Internal registers for NAND operation
    reg [15:0] vec_a_reg, vec_b_reg;
    reg [15:0] nand_stage1;
    reg [15:0] result_reg;
    
    // AXI4-Lite interface FSM states
    localparam IDLE = 2'b00, WRITE = 2'b01, READ = 2'b10, RESP = 2'b11;
    
    // AXI FSM state registers
    reg [1:0] axi_write_state;
    reg [1:0] axi_read_state;
    
    // Address latches
    reg [7:0] write_addr;
    reg [7:0] read_addr;
    
    // Write data latch
    reg [31:0] write_data;
    reg [3:0]  write_strb;
    
    // Control register
    reg [31:0] control_reg;
    
    // Pipeline enable signal derived from control register
    wire pipeline_enable = control_reg[0];
    
    // Write channel state machine
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_write_state <= IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= RESP_OKAY;
            write_addr <= 8'h0;
            write_data <= 32'h0;
            write_strb <= 4'h0;
            vec_a_reg <= 16'h0000;
            vec_b_reg <= 16'h0000;
            control_reg <= 32'h0000_0001; // Enable pipeline by default
        end else begin
            case (axi_write_state)
                IDLE: begin
                    // Accept write address
                    if (s_axi_awvalid && !s_axi_awready) begin
                        s_axi_awready <= 1'b1;
                        write_addr <= s_axi_awaddr;
                        axi_write_state <= WRITE;
                    end
                end
                
                WRITE: begin
                    // Clear awready after capturing address
                    s_axi_awready <= 1'b0;
                    
                    // Accept write data
                    if (s_axi_wvalid && !s_axi_wready) begin
                        s_axi_wready <= 1'b1;
                        write_data <= s_axi_wdata;
                        write_strb <= s_axi_wstrb;
                        
                        // Process write data to appropriate register
                        case (write_addr)
                            REG_VEC_A: begin
                                if (write_strb[0]) vec_a_reg[7:0] <= s_axi_wdata[7:0];
                                if (write_strb[1]) vec_a_reg[15:8] <= s_axi_wdata[15:8];
                            end
                            REG_VEC_B: begin
                                if (write_strb[0]) vec_b_reg[7:0] <= s_axi_wdata[7:0];
                                if (write_strb[1]) vec_b_reg[15:8] <= s_axi_wdata[15:8];
                            end
                            REG_CONTROL: begin
                                if (write_strb[0]) control_reg[7:0] <= s_axi_wdata[7:0];
                                if (write_strb[1]) control_reg[15:8] <= s_axi_wdata[15:8];
                                if (write_strb[2]) control_reg[23:16] <= s_axi_wdata[23:16];
                                if (write_strb[3]) control_reg[31:24] <= s_axi_wdata[31:24];
                            end
                            default: begin
                                // Invalid address
                                s_axi_bresp <= RESP_SLVERR;
                            end
                        endcase
                        
                        axi_write_state <= RESP;
                    end
                end
                
                RESP: begin
                    // Clear wready after capturing data
                    s_axi_wready <= 1'b0;
                    
                    // Send write response
                    if (!s_axi_bvalid) begin
                        s_axi_bvalid <= 1'b1;
                    end else if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        s_axi_bresp <= RESP_OKAY; // Reset for next transaction
                        axi_write_state <= IDLE;
                    end
                end
                
                default: axi_write_state <= IDLE;
            endcase
        end
    end
    
    // Read channel state machine
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_read_state <= IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= RESP_OKAY;
            read_addr <= 8'h0;
            s_axi_rdata <= 32'h0;
        end else begin
            case (axi_read_state)
                IDLE: begin
                    // Accept read address
                    if (s_axi_arvalid && !s_axi_arready) begin
                        s_axi_arready <= 1'b1;
                        read_addr <= s_axi_araddr;
                        axi_read_state <= READ;
                    end
                end
                
                READ: begin
                    // Clear arready after capturing address
                    s_axi_arready <= 1'b0;
                    
                    // Prepare read data
                    case (read_addr)
                        REG_VEC_A: begin
                            s_axi_rdata <= {16'h0000, vec_a_reg};
                            s_axi_rresp <= RESP_OKAY;
                        end
                        REG_VEC_B: begin
                            s_axi_rdata <= {16'h0000, vec_b_reg};
                            s_axi_rresp <= RESP_OKAY;
                        end
                        REG_RESULT: begin
                            s_axi_rdata <= {16'h0000, result_reg};
                            s_axi_rresp <= RESP_OKAY;
                        end
                        REG_CONTROL: begin
                            s_axi_rdata <= control_reg;
                            s_axi_rresp <= RESP_OKAY;
                        end
                        default: begin
                            s_axi_rdata <= 32'h0;
                            s_axi_rresp <= RESP_SLVERR;
                        end
                    endcase
                    
                    s_axi_rvalid <= 1'b1;
                    axi_read_state <= RESP;
                end
                
                RESP: begin
                    // Wait for read ready signal
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        axi_read_state <= IDLE;
                    end
                end
                
                default: axi_read_state <= IDLE;
            endcase
        end
    end
    
    // Core NAND logic with pipeline stages (original functionality)
    // Stage 1: Input registers - handled by AXI write interface
    
    // Stage 2: NAND computation
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            nand_stage1 <= 16'h0000;
        end else if (pipeline_enable) begin
            // Parallel processing of lower and upper bytes for reduced logic depth
            nand_stage1[7:0] <= ~(vec_a_reg[7:0] & vec_b_reg[7:0]);
            nand_stage1[15:8] <= ~(vec_a_reg[15:8] & vec_b_reg[15:8]);
        end
    end
    
    // Stage 3: Output register
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            result_reg <= 16'h0000;
        end else if (pipeline_enable) begin
            result_reg <= nand_stage1;
        end
    end

endmodule