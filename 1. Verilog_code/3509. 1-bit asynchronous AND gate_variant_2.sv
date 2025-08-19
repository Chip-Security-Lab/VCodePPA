//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

// 頂層模塊 - 流水線化AND門
module and_gate_1_async (
    input  wire clk,         // 時鐘信號
    input  wire reset_n,     // 低電平有效復位
    input  wire a,           // 輸入 A
    input  wire b,           // 輸入 B
    output wire y            // 輸出 Y
);
    // 內部信號定義 - 流水線級連接
    wire stage1_result;      // 第一級結果
    reg  stage1_valid;       // 第一級有效標誌
    reg  stage2_data;        // 第二級數據寄存器
    
    // 數據流第一級 - 邏輯運算階段
    logic_operator #(
        .OPERATION_TYPE("AND")
    ) logic_stage (
        .clk       (clk),
        .reset_n   (reset_n),
        .input_a   (a),
        .input_b   (b),
        .result    (stage1_result)
    );
    
    // 流水線控制 - 第一級到第二級
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            stage1_valid <= 1'b0;
        end else begin
            stage1_valid <= 1'b1;  // 輸入數據始終有效
        end
    end
    
    // 數據流第二級 - 流水線寄存器
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            stage2_data <= 1'b0;
        end else if (stage1_valid) begin
            stage2_data <= stage1_result;
        end
    end
    
    // 數據流第三級 - 輸出驅動階段
    output_driver out_stage (
        .clk       (clk),
        .reset_n   (reset_n),
        .data_in   (stage2_data),
        .valid_in  (stage1_valid),
        .data_out  (y)
    );
endmodule

// 邏輯運算子模塊 - 支持時序操作
module logic_operator #(
    parameter OPERATION_TYPE = "AND"  // 支持不同邏輯運算的參數化設計
)(
    input  wire clk,          // 時鐘信號
    input  wire reset_n,      // 低電平有效復位
    input  wire input_a,      // 輸入操作數 A
    input  wire input_b,      // 輸入操作數 B
    output reg  result        // 運算結果
);
    // 內部信號 - 輸入寄存
    reg input_a_reg, input_b_reg;
    
    // 輸入緩存 - 減少扇出負載並提高時序穩定性
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            input_a_reg <= 1'b0;
            input_b_reg <= 1'b0;
        end else begin
            input_a_reg <= input_a;
            input_b_reg <= input_b;
        end
    end
    
    // 邏輯運算處理 - 寄存結果
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            result <= 1'b0;
        end else begin
            case (OPERATION_TYPE)
                "AND": result <= input_a_reg & input_b_reg;
                "OR":  result <= input_a_reg | input_b_reg;
                "XOR": result <= input_a_reg ^ input_b_reg;
                default: result <= input_a_reg & input_b_reg;  // 默認為AND操作
            endcase
        end
    end
endmodule

// 輸出驅動模塊 - 增強型輸出處理
module output_driver (
    input  wire clk,         // 時鐘信號
    input  wire reset_n,     // 低電平有效復位
    input  wire data_in,     // 輸入數據
    input  wire valid_in,    // 輸入有效信號
    output reg  data_out     // 輸出數據
);
    // 輸出驅動邏輯 - 確保在有效數據時更新輸出
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out <= 1'b0;
        end else if (valid_in) begin
            data_out <= data_in;
        end
    end
endmodule

`default_nettype wire