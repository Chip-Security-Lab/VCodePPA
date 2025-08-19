//SystemVerilog
// 顶层模块
module rle_encoder #(parameter DATA_WIDTH = 8) (
    input                       clk,
    input                       rst_n,
    input                       valid_in,
    input      [DATA_WIDTH-1:0] data_in,
    output                      valid_out,
    output     [DATA_WIDTH-1:0] data_out,
    output     [DATA_WIDTH-1:0] count_out
);
    // 内部信号
    wire [DATA_WIDTH-1:0] data_in_registered;
    wire                  valid_in_registered;
    wire                  data_match;
    wire                  count_overflow;
    wire [DATA_WIDTH-1:0] current_data;
    wire [DATA_WIDTH-1:0] run_count;
    
    // 输入寄存器子模块
    input_register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) input_reg_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (data_in),
        .valid_in       (valid_in),
        .data_out       (data_in_registered),
        .valid_out      (valid_in_registered)
    );
    
    // 比较计算子模块
    comparator #(
        .DATA_WIDTH(DATA_WIDTH)
    ) comparator_inst (
        .current_data   (current_data),
        .data_in        (data_in_registered),
        .run_count      (run_count),
        .data_match     (data_match),
        .count_overflow (count_overflow)
    );
    
    // RLE核心处理子模块
    rle_processor #(
        .DATA_WIDTH(DATA_WIDTH)
    ) processor_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .valid_in       (valid_in_registered),
        .data_in        (data_in_registered),
        .data_match     (data_match),
        .count_overflow (count_overflow),
        .current_data   (current_data),
        .run_count      (run_count),
        .valid_out      (valid_out),
        .data_out       (data_out),
        .count_out      (count_out)
    );
    
endmodule

// 输入寄存器子模块
module input_register #(parameter DATA_WIDTH = 8) (
    input                       clk,
    input                       rst_n,
    input      [DATA_WIDTH-1:0] data_in,
    input                       valid_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg                  valid_out
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            data_out <= data_in;
            valid_out <= valid_in;
        end
    end
    
endmodule

// 比较计算子模块 - 使用先行借位比较器
module comparator #(parameter DATA_WIDTH = 8) (
    input      [DATA_WIDTH-1:0] current_data,
    input      [DATA_WIDTH-1:0] data_in,
    input      [DATA_WIDTH-1:0] run_count,
    output                      data_match,
    output                      count_overflow
);
    
    // 先行借位比较逻辑
    wire [DATA_WIDTH:0] borrow;
    wire [DATA_WIDTH-1:0] diff;
    
    // 初始无借位
    assign borrow[0] = 1'b0;
    
    // 先行借位减法器实现用于比较
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : gen_borrow
            // 借位生成条件: 当前位为0且下一位为1，或当前位为0且有借位，或下一位为1且有借位
            assign borrow[i+1] = (~data_in[i] & current_data[i]) | 
                                 (~data_in[i] & borrow[i]) | 
                                 (current_data[i] & borrow[i]);
            
            // 差值计算 = A XOR B XOR 借位
            assign diff[i] = data_in[i] ^ current_data[i] ^ borrow[i];
        end
    endgenerate
    
    // 如果差值为0，则数据匹配
    assign data_match = (diff == {DATA_WIDTH{1'b0}});
    
    // 判断计数是否溢出
    // 使用先行借位检查run_count是否等于最大值
    wire [DATA_WIDTH:0] max_check_borrow;
    wire [DATA_WIDTH-1:0] max_check_diff;
    
    assign max_check_borrow[0] = 1'b0;
    
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : gen_max_check
            assign max_check_borrow[i+1] = (~run_count[i] & 1'b1) | 
                                           (~run_count[i] & max_check_borrow[i]) | 
                                           (1'b1 & max_check_borrow[i]);
            
            assign max_check_diff[i] = run_count[i] ^ 1'b1 ^ max_check_borrow[i];
        end
    endgenerate
    
    // 如果run_count与全1相减结果为0，则溢出
    assign count_overflow = (max_check_diff == {DATA_WIDTH{1'b0}});
    
endmodule

// RLE核心处理子模块
module rle_processor #(parameter DATA_WIDTH = 8) (
    input                       clk,
    input                       rst_n,
    input                       valid_in,
    input      [DATA_WIDTH-1:0] data_in,
    input                       data_match,
    input                       count_overflow,
    output reg [DATA_WIDTH-1:0] current_data,
    output reg [DATA_WIDTH-1:0] run_count,
    output reg                  valid_out,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg [DATA_WIDTH-1:0] count_out
);
    
    // 增量计算逻辑 - 使用先行进位加法器
    wire [DATA_WIDTH:0] carry;
    wire [DATA_WIDTH-1:0] next_count;
    
    // 初始无进位
    assign carry[0] = 1'b0;
    
    // 先行进位加法器实现
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : gen_carry
            if (i == 0) begin
                // 第一位的进位计算
                assign carry[i+1] = run_count[i] & 1'b1;
                assign next_count[i] = run_count[i] ^ 1'b1;
            end else begin
                // 其余位的进位计算
                assign carry[i+1] = (run_count[i] & carry[i]);
                assign next_count[i] = run_count[i] ^ carry[i];
            end
        end
    endgenerate
    
    // 主处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_data <= {DATA_WIDTH{1'b0}};
            run_count <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
            data_out <= {DATA_WIDTH{1'b0}};
            count_out <= {DATA_WIDTH{1'b0}};
        end else if (valid_in) begin
            if (data_match && !count_overflow) begin
                // 相同数据且计数未溢出，计数加1（使用先行进位加法结果）
                run_count <= next_count;
                valid_out <= 1'b0;
            end else begin
                // 不同数据或计数溢出，输出当前运行长度并开始新计数
                data_out <= current_data;
                count_out <= run_count;
                valid_out <= (run_count != {DATA_WIDTH{1'b0}});
                current_data <= data_in;
                run_count <= {{(DATA_WIDTH-1){1'b0}}, 1'b1}; // 设置为1
            end
        end else begin
            valid_out <= 1'b0;
        end
    end
    
endmodule