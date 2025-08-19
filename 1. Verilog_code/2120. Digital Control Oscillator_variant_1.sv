//SystemVerilog
// SystemVerilog
module digital_ctrl_osc(
    input wire aclk,              // AXI clock
    input wire aresetn,           // AXI reset, active low
    
    // AXI4-Lite slave interface
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output wire s_axil_awready,
    
    // Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output wire s_axil_wready,
    
    // Write Response Channel
    output wire [1:0] s_axil_bresp,
    output wire s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output wire s_axil_arready,
    
    // Read Data Channel
    output wire [31:0] s_axil_rdata,
    output wire [1:0] s_axil_rresp,
    output wire s_axil_rvalid,
    input wire s_axil_rready,
    
    // Original module output
    output wire clk_out
);
    
    // Internal registers for AXI4-Lite interface
    reg s_axil_awready_reg, s_axil_wready_reg;
    reg [1:0] s_axil_bresp_reg;
    reg s_axil_bvalid_reg;
    reg s_axil_arready_reg;
    reg [31:0] s_axil_rdata_reg;
    reg [1:0] s_axil_rresp_reg;
    reg s_axil_rvalid_reg;
    
    // Register address mapping
    localparam ADDR_CTRL_WORD = 4'h0;    // Address 0x00: Control word
    localparam ADDR_ENABLE    = 4'h4;    // Address 0x04: Enable bit
    
    // Internal control registers
    reg [7:0] ctrl_word_reg;
    reg enable_reg;
    
    // Internal signals for clock generation
    wire internal_clk;
    wire reset;
    
    assign reset = ~aresetn;
    
    // AXI4-Lite output assignments
    assign s_axil_awready = s_axil_awready_reg;
    assign s_axil_wready = s_axil_wready_reg;
    assign s_axil_bresp = s_axil_bresp_reg;
    assign s_axil_bvalid = s_axil_bvalid_reg;
    assign s_axil_arready = s_axil_arready_reg;
    assign s_axil_rdata = s_axil_rdata_reg;
    assign s_axil_rresp = s_axil_rresp_reg;
    assign s_axil_rvalid = s_axil_rvalid_reg;
    
    // Write Address Channel handling
    always @(posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            s_axil_awready_reg <= 1'b0;
        end else begin
            if (~s_axil_awready_reg && s_axil_awvalid && s_axil_wvalid && ~s_axil_bvalid_reg) begin
                s_axil_awready_reg <= 1'b1;
            end else begin
                s_axil_awready_reg <= 1'b0;
            end
        end
    end
    
    // Write Data Channel handling
    always @(posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            s_axil_wready_reg <= 1'b0;
            s_axil_bresp_reg <= 2'b00;  // OKAY response
            s_axil_bvalid_reg <= 1'b0;
            ctrl_word_reg <= 8'h00;
            enable_reg <= 1'b0;
        end else begin
            if (~s_axil_wready_reg && s_axil_awvalid && s_axil_wvalid && ~s_axil_bvalid_reg) begin
                s_axil_wready_reg <= 1'b1;
                
                // Write to appropriate register based on address
                case (s_axil_awaddr[3:0])
                    ADDR_CTRL_WORD: begin
                        if (s_axil_wstrb[0]) ctrl_word_reg <= s_axil_wdata[7:0];
                    end
                    ADDR_ENABLE: begin
                        if (s_axil_wstrb[0]) enable_reg <= s_axil_wdata[0];
                    end
                    default: begin
                        // No valid register address
                    end
                endcase
            end else begin
                s_axil_wready_reg <= 1'b0;
            end
            
            // Handle write response
            if (~s_axil_bvalid_reg && s_axil_awready_reg && s_axil_wready_reg) begin
                s_axil_bvalid_reg <= 1'b1;
                s_axil_bresp_reg <= 2'b00;  // OKAY response
            end else if (s_axil_bvalid_reg && s_axil_bready) begin
                s_axil_bvalid_reg <= 1'b0;
            end
        end
    end
    
    // Read Address Channel handling
    always @(posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            s_axil_arready_reg <= 1'b0;
            s_axil_rvalid_reg <= 1'b0;
            s_axil_rresp_reg <= 2'b00;  // OKAY response
        end else begin
            if (~s_axil_arready_reg && s_axil_arvalid && ~s_axil_rvalid_reg) begin
                s_axil_arready_reg <= 1'b1;
            end else begin
                s_axil_arready_reg <= 1'b0;
            end
            
            // Handle read data
            if (s_axil_arready_reg && s_axil_arvalid && ~s_axil_rvalid_reg) begin
                s_axil_rvalid_reg <= 1'b1;
                s_axil_rresp_reg <= 2'b00;  // OKAY response
                
                // Read from appropriate register based on address
                case (s_axil_araddr[3:0])
                    ADDR_CTRL_WORD: begin
                        s_axil_rdata_reg <= {24'h000000, ctrl_word_reg};
                    end
                    ADDR_ENABLE: begin
                        s_axil_rdata_reg <= {31'h00000000, enable_reg};
                    end
                    default: begin
                        s_axil_rdata_reg <= 32'h00000000;
                    end
                endcase
            end else if (s_axil_rvalid_reg && s_axil_rready) begin
                s_axil_rvalid_reg <= 1'b0;
            end
        end
    end
    
    // 实例化时钟生成器子模块
    clock_generator clk_gen_inst (
        .reset(reset),
        .internal_clk(internal_clk)
    );
    
    // 实例化可控分频器子模块
    programmable_divider div_inst (
        .enable(enable_reg),
        .ctrl_word(ctrl_word_reg),
        .reset(reset),
        .internal_clk(internal_clk),
        .clk_out(clk_out)
    );
    
endmodule

module clock_generator(
    input reset,
    output internal_clk
);
    reg [3:0] clk_divider;
    
    // 通过自循环驱动伪时钟逻辑
    always @(posedge reset or posedge internal_clk) begin
        if (reset)
            clk_divider <= 4'd0;
        else
            clk_divider <= clk_divider + 4'd1;
    end
    
    assign internal_clk = clk_divider[3]; // 分频模拟时钟源
endmodule

module programmable_divider(
    input enable,
    input [7:0] ctrl_word,
    input reset,
    input internal_clk,
    output reg clk_out
);
    reg [7:0] delay_counter;
    
    // 可编程分频逻辑
    always @(posedge internal_clk or posedge reset) begin
        if (reset) begin
            delay_counter <= 8'd0;
            clk_out <= 1'b0;
        end else if (enable) begin
            if (delay_counter >= ctrl_word) begin
                delay_counter <= 8'd0;
                clk_out <= ~clk_out;
            end else begin
                delay_counter <= delay_counter + 8'd1;
            end
        end
    end
endmodule