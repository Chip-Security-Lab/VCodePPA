//SystemVerilog
module sync_controlled_bidir_shifter (
    input                  clock,
    input                  resetn,
    input      [31:0]      data_in,
    input      [4:0]       shift_amount,
    input      [1:0]       mode,  // 00:left logical, 01:right logical
                                  // 10:left rotate, 11:right rotate
    input                  valid_in,  // 数据有效信号
    output                 ready_out, // 准备接收信号
    output reg             valid_out, // 输出数据有效信号
    input                  ready_in,  // 下游准备接收信号
    output     [31:0]      data_out
);
    // 握手控制信号
    reg processing;
    wire transaction_complete;
    
    // 数据缓冲区
    reg [31:0] data_buffer;
    reg [4:0]  shift_buffer;
    reg [1:0]  mode_buffer;
    
    // Shift operation results (pre-registered)
    reg [31:0] shift_left_result;
    reg [31:0] shift_right_result;
    reg [31:0] rotate_left_result;
    reg [31:0] mult_result_reg;
    
    // Final output register moved to individual operation paths
    reg [31:0] data_out_reg;
    assign data_out = data_out_reg;
    
    // Temporary variables for Karatsuba multiplication
    wire [31:0] mult_result;
    reg  [31:0] mult_operand_a;
    reg  [31:0] mult_operand_b;
    
    // Valid-Ready握手信号处理
    assign ready_out = !processing || transaction_complete;
    assign transaction_complete = valid_out && ready_in;
    
    // 输入数据缓冲控制
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            processing <= 1'b0;
            data_buffer <= 32'h0;
            shift_buffer <= 5'h0;
            mode_buffer <= 2'b0;
        end else begin
            if (!processing && valid_in && ready_out) begin
                // 接收新数据
                data_buffer <= data_in;
                shift_buffer <= shift_amount;
                mode_buffer <= mode;
                processing <= 1'b1;
            end else if (transaction_complete) begin
                // 数据已被下游接收，可以处理新数据
                processing <= 1'b0;
            end
        end
    end
    
    // Pre-compute all possible shift operations and register them
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            shift_left_result <= 32'h0;
            shift_right_result <= 32'h0;
            rotate_left_result <= 32'h0;
            mult_result_reg <= 32'h0;
        end else if (processing && !valid_out) begin
            shift_left_result <= data_buffer << shift_buffer;
            shift_right_result <= data_buffer >> shift_buffer;
            rotate_left_result <= {data_buffer, data_buffer} >> (32 - shift_buffer);
            mult_result_reg <= mult_result;
        end
    end
    
    // Output selection based on mode (registered)
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            data_out_reg <= 32'h0;
        end else if (processing && !valid_out) begin
            case(mode_buffer)
                2'b00: data_out_reg <= shift_left_result;
                2'b01: data_out_reg <= shift_right_result;
                2'b10: data_out_reg <= rotate_left_result;
                2'b11: data_out_reg <= mult_result_reg;
            endcase
        end
    end
    
    // 输出控制
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            valid_out <= 1'b0;
        end else begin
            if (processing && !valid_out) begin
                // 结果计算完成后设置valid_out (延迟一个周期)
                valid_out <= 1'b1;
            end else if (transaction_complete) begin
                // 交易完成后复位valid_out
                valid_out <= 1'b0;
            end
        end
    end
    
    // Karatsuba multiplier instantiation
    karatsuba_multiplier_32bit karatsuba_mult (
        .a(mult_operand_a),
        .b(mult_operand_b),
        .result(mult_result)
    );
    
    // Select operands for multiplication based on shift_amount
    always @(*) begin
        mult_operand_a = data_buffer;
        mult_operand_b = {27'b0, shift_buffer};
    end
endmodule

// Recursive Karatsuba Multiplier for 32-bit operands
module karatsuba_multiplier_32bit (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] result
);
    wire [31:0] product;
    
    // Instantiate the recursive implementation
    karatsuba_recursive #(
        .WIDTH(32)
    ) karatsuba_impl (
        .a(a),
        .b(b),
        .result(product)
    );
    
    // Truncate the full product to 32 bits
    assign result = product[31:0];
endmodule

// Recursive Karatsuba implementation with parameterized width
module karatsuba_recursive #(
    parameter WIDTH = 32
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [2*WIDTH-1:0] result
);
    generate
        if (WIDTH <= 8) begin: base_case
            // Base case: use direct multiplication for small widths
            assign result = a * b;
        end else begin: recursive_case
            // Split operands into high and low halves
            localparam HALF_WIDTH = WIDTH / 2;
            
            wire [HALF_WIDTH-1:0] a_low, b_low;
            wire [HALF_WIDTH-1:0] a_high, b_high;
            
            assign a_low = a[HALF_WIDTH-1:0];
            assign a_high = a[WIDTH-1:HALF_WIDTH];
            assign b_low = b[HALF_WIDTH-1:0];
            assign b_high = b[WIDTH-1:HALF_WIDTH];
            
            // Intermediate results
            wire [2*HALF_WIDTH-1:0] z0, z1, z2;
            wire [HALF_WIDTH:0] a_sum, b_sum;
            wire [2*HALF_WIDTH+1:0] z1_full;
            
            // Compute sums
            assign a_sum = a_low + a_high;
            assign b_sum = b_low + b_high;
            
            // Recursive multiplication calls
            karatsuba_recursive #(
                .WIDTH(HALF_WIDTH)
            ) low_mult (
                .a(a_low),
                .b(b_low),
                .result(z0)
            );
            
            karatsuba_recursive #(
                .WIDTH(HALF_WIDTH)
            ) high_mult (
                .a(a_high),
                .b(b_high),
                .result(z2)
            );
            
            karatsuba_recursive #(
                .WIDTH(HALF_WIDTH+1)
            ) mid_mult (
                .a(a_sum),
                .b(b_sum),
                .result(z1_full)
            );
            
            // z1 = (a_low + a_high) * (b_low + b_high) - z0 - z2
            assign z1 = z1_full[2*HALF_WIDTH:0] - z0 - z2;
            
            // Final result: z2 * 2^(2*HALF_WIDTH) + z1 * 2^HALF_WIDTH + z0
            assign result = {z2, {HALF_WIDTH{1'b0}}, {HALF_WIDTH{1'b0}}} + {{HALF_WIDTH{1'b0}}, z1, {HALF_WIDTH{1'b0}}} + {{WIDTH{1'b0}}, z0};
        end
    endgenerate
endmodule