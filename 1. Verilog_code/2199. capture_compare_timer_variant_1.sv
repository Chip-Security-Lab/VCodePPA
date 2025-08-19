//SystemVerilog
// SystemVerilog (IEEE 1364-2005)
module capture_compare_timer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire capture_trig,
    input wire [WIDTH-1:0] compare_val,
    output wire compare_match,
    output wire [WIDTH-1:0] capture_val
);
    // 内部信号
    wire [WIDTH-1:0] counter_value;
    wire [WIDTH-1:0] diff;
    wire [WIDTH:0] borrow;
    wire equality_detected;

    // 计数器子模块
    counter_module #(
        .WIDTH(WIDTH)
    ) counter_inst (
        .clk(clk),
        .rst(rst),
        .counter_value(counter_value)
    );

    // 比较器子模块
    comparator_module #(
        .WIDTH(WIDTH)
    ) comparator_inst (
        .counter_value(counter_value),
        .compare_val(compare_val),
        .diff(diff),
        .borrow(borrow),
        .equality_detected(equality_detected)
    );

    // 捕获子模块
    capture_module #(
        .WIDTH(WIDTH)
    ) capture_inst (
        .clk(clk),
        .rst(rst),
        .capture_trig(capture_trig),
        .counter_value(counter_value),
        .capture_val(capture_val)
    );

    // 匹配输出子模块
    match_output_module match_inst (
        .clk(clk),
        .rst(rst),
        .equality_detected(equality_detected),
        .compare_match(compare_match)
    );
endmodule

// 计数器子模块
module counter_module #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst,
    output reg [WIDTH-1:0] counter_value
);
    always @(posedge clk) begin
        if (rst) begin
            counter_value <= {WIDTH{1'b0}};
        end else begin
            counter_value <= counter_value + 1'b1;
        end
    end
endmodule

// 比较器子模块
module comparator_module #(
    parameter WIDTH = 16
)(
    input wire [WIDTH-1:0] counter_value,
    input wire [WIDTH-1:0] compare_val,
    output wire [WIDTH-1:0] diff,
    output wire [WIDTH:0] borrow,
    output wire equality_detected
);
    // 先行借位减法器实现
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_borrow
            assign borrow[i+1] = (~counter_value[i] & compare_val[i]) | 
                               ((~counter_value[i] | compare_val[i]) & borrow[i]);
            assign diff[i] = counter_value[i] ^ compare_val[i] ^ borrow[i];
        end
    endgenerate
    
    // 检测相等条件
    assign equality_detected = (diff == {WIDTH{1'b0}} && borrow[WIDTH] == 1'b0);
endmodule

// 捕获子模块
module capture_module #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire capture_trig,
    input wire [WIDTH-1:0] counter_value,
    output reg [WIDTH-1:0] capture_val
);
    reg capture_trig_prev;
    
    always @(posedge clk) begin
        if (rst) begin
            capture_val <= {WIDTH{1'b0}};
            capture_trig_prev <= 1'b0;
        end else begin
            capture_trig_prev <= capture_trig;
            
            if (capture_trig && !capture_trig_prev) begin
                capture_val <= counter_value;
            end
        end
    end
endmodule

// 匹配输出子模块
module match_output_module (
    input wire clk,
    input wire rst,
    input wire equality_detected,
    output reg compare_match
);
    always @(posedge clk) begin
        if (rst) begin
            compare_match <= 1'b0;
        end else begin
            compare_match <= equality_detected;
        end
    end
endmodule