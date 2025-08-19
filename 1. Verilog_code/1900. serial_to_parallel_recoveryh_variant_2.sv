//SystemVerilog
module serial_to_parallel_recovery #(
    parameter WIDTH = 8
)(
    input  wire           bit_clk,
    input  wire           reset,
    input  wire           serial_in,
    input  wire           frame_sync,
    output wire [WIDTH-1:0] parallel_out,
    output wire            data_valid
);

    // 数据路径寄存器
    reg             serial_in_stage1;
    reg             serial_in_stage2;
    reg [WIDTH-2:0] shift_reg_stage1;
    reg [WIDTH-2:0] shift_reg_stage2;
    
    // 控制路径寄存器
    reg [3:0]       bit_counter;
    reg             word_complete_stage1;
    reg             word_complete_stage2;
    reg             frame_sync_stage1;
    
    // 输出寄存器
    reg [WIDTH-1:0] parallel_out_reg;
    reg             data_valid_reg;
    
    // 阶段1: 输入捕获和同步
    always @(posedge bit_clk or posedge reset) begin
        if (reset) begin
            serial_in_stage1 <= 1'b0;
            frame_sync_stage1 <= 1'b0;
        end else begin
            serial_in_stage1 <= serial_in;
            frame_sync_stage1 <= frame_sync;
        end
    end
    
    // 阶段2: 位计数和序列检测控制
    always @(posedge bit_clk or posedge reset) begin
        if (reset) begin
            bit_counter <= 4'h0;
        end else if (frame_sync_stage1) begin
            bit_counter <= 4'h0;
        end else begin
            bit_counter <= (bit_counter == WIDTH-1) ? 4'h0 : bit_counter + 4'h1;
        end
    end
    
    // 完成检测信号
    wire word_complete = (bit_counter == WIDTH-1);
    
    // 阶段3: 移位寄存器第一级 - 数据捕获
    always @(posedge bit_clk or posedge reset) begin
        if (reset) begin
            shift_reg_stage1 <= {(WIDTH-1){1'b0}};
            word_complete_stage1 <= 1'b0;
            serial_in_stage2 <= 1'b0;
        end else begin
            shift_reg_stage1 <= frame_sync_stage1 ? {(WIDTH-1){1'b0}} : 
                               {shift_reg_stage1[WIDTH-3:0], serial_in_stage1};
            word_complete_stage1 <= word_complete;
            serial_in_stage2 <= serial_in_stage1;
        end
    end
    
    // 阶段4: 移位寄存器第二级 - 数据稳定
    always @(posedge bit_clk or posedge reset) begin
        if (reset) begin
            shift_reg_stage2 <= {(WIDTH-1){1'b0}};
            word_complete_stage2 <= 1'b0;
        end else begin
            shift_reg_stage2 <= shift_reg_stage1;
            word_complete_stage2 <= word_complete_stage1;
        end
    end
    
    // 阶段5: 输出生成和有效控制
    always @(posedge bit_clk or posedge reset) begin
        if (reset) begin
            parallel_out_reg <= {WIDTH{1'b0}};
            data_valid_reg <= 1'b0;
        end else if (frame_sync_stage1) begin
            data_valid_reg <= 1'b0;
        end else if (word_complete_stage2) begin
            parallel_out_reg <= {shift_reg_stage2, serial_in_stage2};
            data_valid_reg <= 1'b1;
        end else begin
            data_valid_reg <= 1'b0;
        end
    end
    
    // 输出赋值
    assign parallel_out = parallel_out_reg;
    assign data_valid = data_valid_reg;

endmodule