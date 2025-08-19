//SystemVerilog
module rgb_to_gray_codec (
    // Clock and Reset
    input wire        s_axi_aclk,
    input wire        s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input wire [3:0]  s_axi_awaddr,
    input wire        s_axi_awvalid,
    output reg        s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0]  s_axi_wstrb,
    input wire        s_axi_wvalid,
    output reg        s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output reg [1:0]  s_axi_bresp,
    output reg        s_axi_bvalid,
    input wire        s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input wire [3:0]  s_axi_araddr,
    input wire        s_axi_arvalid,
    output reg        s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0]  s_axi_rresp,
    output reg        s_axi_rvalid,
    input wire        s_axi_rready
);

    // Internal registers
    reg [23:0] rgb_pixel_reg;
    reg [7:0]  gray_out_reg;
    
    // Address decode parameters
    localparam ADDR_RGB_PIXEL = 4'h0;
    localparam ADDR_GRAY_OUT  = 4'h4;
    
    // AXI4-Lite response codes
    localparam RESP_OKAY   = 2'b00;
    localparam RESP_ERROR  = 2'b10;

    // Grayscale conversion pipeline stages
    // Stage 1: Component multiplication
    reg [15:0] r_contrib_stage1;
    reg [15:0] g_contrib_stage1;
    reg [15:0] b_contrib_stage1;
    
    // Stage 2: Partial sum (R+G)
    reg [15:0] rg_sum_stage2;
    reg [15:0] b_contrib_stage2;
    
    // Stage 3: Final sum (R+G+B)
    reg [15:0] total_sum_stage3;
    
    // Stage 4: Division (shift right)
    reg [7:0] gray_calc_stage4;

    // Grayscale conversion pipelined logic
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            // Reset all pipeline stages
            r_contrib_stage1 <= 16'h0;
            g_contrib_stage1 <= 16'h0;
            b_contrib_stage1 <= 16'h0;
            rg_sum_stage2 <= 16'h0;
            b_contrib_stage2 <= 16'h0;
            total_sum_stage3 <= 16'h0;
            gray_calc_stage4 <= 8'h0;
            gray_out_reg <= 8'h0;
        end else begin
            // Stage 1: Calculate individual RGB contributions
            r_contrib_stage1 <= 77 * rgb_pixel_reg[23:16];  // 0.299 * 256 ~= 77
            g_contrib_stage1 <= 150 * rgb_pixel_reg[15:8];  // 0.587 * 256 ~= 150
            b_contrib_stage1 <= 29 * rgb_pixel_reg[7:0];    // 0.114 * 256 ~= 29
            
            // Stage 2: Partial sum calculation
            rg_sum_stage2 <= r_contrib_stage1 + g_contrib_stage1;
            b_contrib_stage2 <= b_contrib_stage1;
            
            // Stage 3: Calculate total sum
            total_sum_stage3 <= rg_sum_stage2 + b_contrib_stage2;
            
            // Stage 4: Final division
            gray_calc_stage4 <= total_sum_stage3 >> 8;
            
            // Output stage
            gray_out_reg <= gray_calc_stage4;
        end
    end
    
    // Write Address Channel handling
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
        end else begin
            if (~s_axi_awready && s_axi_awvalid) begin
                s_axi_awready <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end
    
    // Write Data Channel handling
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
            rgb_pixel_reg <= 24'h0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= RESP_OKAY;
        end else begin
            if (~s_axi_wready && s_axi_wvalid && s_axi_awready) begin
                s_axi_wready <= 1'b1;
                
                // Write based on address
                case (s_axi_awaddr)
                    ADDR_RGB_PIXEL: begin
                        if (s_axi_wstrb[0]) rgb_pixel_reg[7:0]   <= s_axi_wdata[7:0];
                        if (s_axi_wstrb[1]) rgb_pixel_reg[15:8]  <= s_axi_wdata[15:8];
                        if (s_axi_wstrb[2]) rgb_pixel_reg[23:16] <= s_axi_wdata[23:16];
                    end
                    default: begin
                        // Invalid address
                        s_axi_bresp <= RESP_ERROR;
                    end
                endcase
                
                s_axi_bvalid <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end
            
            // Handle write response
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                s_axi_bresp <= RESP_OKAY;
            end
        end
    end
    
    // Read Address Channel handling
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end
        end
    end
    
    // Read Data Channel handling
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= RESP_OKAY;
            s_axi_rdata <= 32'h0;
        end else begin
            if (~s_axi_rvalid && s_axi_arready) begin
                s_axi_rvalid <= 1'b1;
                
                // Read based on address
                case (s_axi_araddr)
                    ADDR_RGB_PIXEL: begin
                        s_axi_rdata <= {8'h0, rgb_pixel_reg};
                    end
                    ADDR_GRAY_OUT: begin
                        s_axi_rdata <= {24'h0, gray_out_reg};
                    end
                    default: begin
                        // Invalid address
                        s_axi_rresp <= RESP_ERROR;
                        s_axi_rdata <= 32'h0;
                    end
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
                s_axi_rresp <= RESP_OKAY;
            end
        end
    end

endmodule