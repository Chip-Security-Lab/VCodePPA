//SystemVerilog

// Submodule for subtraction
module subtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] input_data,
    output reg [WIDTH-1:0] sub_result
);
    always @* begin
        sub_result = ~input_data + 1; // 取反加一实现减法
    end
endmodule

// Submodule for shadow storage
module shadow_store #(parameter WIDTH=8) (
    input clk,
    input enable,
    input [WIDTH-1:0] sub_result,
    output reg [WIDTH-1:0] shadow_store
);
    always @(posedge clk) begin
        if (enable) begin
            shadow_store <= shadow_store + sub_result; // 更新shadow_store
        end
    end
endmodule

// Top-level module
module shadow_reg_no_reset #(parameter WIDTH=8) (
    input clk, 
    input enable,
    input [WIDTH-1:0] input_data,
    output reg [WIDTH-1:0] output_data
);
    wire [WIDTH-1:0] sub_result;
    wire [WIDTH-1:0] shadow_store_signal;

    // Instantiate the subtractor submodule
    subtractor #(WIDTH) sub_inst (
        .input_data(input_data),
        .sub_result(sub_result)
    );

    // Instantiate the shadow store submodule
    shadow_store #(WIDTH) store_inst (
        .clk(clk),
        .enable(enable),
        .sub_result(sub_result),
        .shadow_store(shadow_store_signal)
    );

    always @(posedge clk) begin
        output_data <= shadow_store_signal; // 输出结果
    end
endmodule