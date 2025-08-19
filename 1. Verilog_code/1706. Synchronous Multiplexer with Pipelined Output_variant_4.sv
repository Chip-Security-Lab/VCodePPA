//SystemVerilog
module pipeline_mux(
    input clk, resetn,
    input [15:0] in1, in2, in3, in4,
    input [1:0] sel,
    output reg [15:0] pipe_out
);

    localparam RESET_VALUE = 16'h0;
    localparam DATA_WIDTH = 16;
    
    reg [DATA_WIDTH-1:0] stage1_reg;
    reg [DATA_WIDTH-1:0] stage2_reg;
    reg [1:0] sel_stage1;
    reg [1:0] sel_stage2;
    reg valid_stage1;
    reg valid_stage2;
    
    // 优化后的选择逻辑
    wire [DATA_WIDTH-1:0] mux1_out = (sel == 2'b00) ? in1 :
                                    (sel == 2'b01) ? in2 :
                                    (sel == 2'b10) ? in3 : in4;
    
    // 简化第二级选择逻辑
    wire [DATA_WIDTH-1:0] mux2_out = stage1_reg;
    
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            {stage1_reg, stage2_reg, sel_stage1, sel_stage2} <= {4{RESET_VALUE}};
            {valid_stage1, valid_stage2} <= 2'b0;
            pipe_out <= RESET_VALUE;
        end else begin
            stage1_reg <= mux1_out;
            sel_stage1 <= sel;
            valid_stage1 <= 1'b1;
            
            stage2_reg <= mux2_out;
            sel_stage2 <= sel_stage1;
            valid_stage2 <= valid_stage1;
            
            pipe_out <= valid_stage2 ? stage2_reg : RESET_VALUE;
        end
    end
endmodule