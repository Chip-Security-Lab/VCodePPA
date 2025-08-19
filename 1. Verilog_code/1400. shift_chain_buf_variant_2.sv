//SystemVerilog
module shift_chain_buf #(parameter DW=8, DEPTH=4) (
    input clk, en,
    input serial_in,
    input [DW-1:0] parallel_in,
    input load,
    input rst,
    output serial_out,
    output [DW*DEPTH-1:0] parallel_out,
    
    // 流水线控制信号
    input valid_in,
    output valid_out,
    input ready_in,
    output ready_out
);
    // 流水线寄存器和控制信号
    reg [DW-1:0] shift_reg_stage1 [0:DEPTH-1];
    reg [DW-1:0] shift_reg_stage2 [0:DEPTH-1];
    reg [DW-1:0] shift_reg_stage3 [0:DEPTH-1];
    
    // 流水线控制信号寄存器
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 反压控制
    wire stall = valid_out && !ready_in;
    assign ready_out = !stall;
    
    // 第一级流水线 - 输入处理
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            integer i;
            for(i=0; i<DEPTH; i=i+1)
                shift_reg_stage1[i] <= 0;
            valid_stage1 <= 0;
        end else if (en && ready_out && !stall) begin
            valid_stage1 <= valid_in;
            if(load) begin
                shift_reg_stage1[0] <= parallel_in;
                shift_reg_stage1[1] <= shift_reg_stage1[0];
                shift_reg_stage1[2] <= shift_reg_stage1[1];
                shift_reg_stage1[3] <= shift_reg_stage1[2];
            end
            else begin
                shift_reg_stage1[0] <= {{(DW-1){1'b0}}, serial_in};
                shift_reg_stage1[1] <= shift_reg_stage1[0];
                shift_reg_stage1[2] <= shift_reg_stage1[1];
                shift_reg_stage1[3] <= shift_reg_stage1[2];
            end
        end
    end
    
    // 第二级流水线 - 中间处理
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            integer i;
            for(i=0; i<DEPTH; i=i+1)
                shift_reg_stage2[i] <= 0;
            valid_stage2 <= 0;
        end else if (en && !stall) begin
            valid_stage2 <= valid_stage1;
            shift_reg_stage2[0] <= shift_reg_stage1[0];
            shift_reg_stage2[1] <= shift_reg_stage1[1];
            shift_reg_stage2[2] <= shift_reg_stage1[2];
            shift_reg_stage2[3] <= shift_reg_stage1[3];
        end
    end
    
    // 第三级流水线 - 输出处理
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            integer i;
            for(i=0; i<DEPTH; i=i+1)
                shift_reg_stage3[i] <= 0;
            valid_stage3 <= 0;
        end else if (en && !stall) begin
            valid_stage3 <= valid_stage2;
            shift_reg_stage3[0] <= shift_reg_stage2[0];
            shift_reg_stage3[1] <= shift_reg_stage2[1];
            shift_reg_stage3[2] <= shift_reg_stage2[2];
            shift_reg_stage3[3] <= shift_reg_stage2[3];
        end
    end
    
    // 输出赋值
    assign serial_out = shift_reg_stage3[DEPTH-1][0];
    assign valid_out = valid_stage3;
    
    // 并行输出生成
    genvar g;
    generate
        for(g=0; g<DEPTH; g=g+1)
            assign parallel_out[g*DW +: DW] = shift_reg_stage3[g];
    endgenerate
endmodule