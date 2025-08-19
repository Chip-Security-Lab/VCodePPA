//SystemVerilog
module UART_ProgrammableParity #(
    parameter DYNAMIC_CONFIG = 1
)(
    input  wire clk,
    input  wire rst_n,
    input  wire cfg_parity_en,
    input  wire cfg_parity_type,
    input  wire [7:0] tx_payload,
    output reg  [7:0] rx_payload,
    input  wire [7:0] rx_shift,
    output reg  rx_parity_err,
    output wire tx_parity
);

// 奇偶生成函数
function calc_parity;
    input [7:0] data;
    input parity_type;
    reg sum;
    begin
        sum = ^data;
        calc_parity = (parity_type) ? ~sum : sum;
    end
endfunction

reg parity_en;
reg [7:0] tx_data;
reg tx_parity_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        parity_en      <= 1'b0;
        rx_parity_err  <= 1'b0;
        rx_payload     <= 8'b0;
        tx_data        <= 8'b0;
        tx_parity_reg  <= 1'b0;
    end else begin
        parity_en      <= cfg_parity_en;
        tx_data        <= tx_payload;
        rx_payload     <= rx_shift[7:0];

        // 扁平化接收端校验检测
        if (cfg_parity_en && (calc_parity(rx_shift[7:0], cfg_parity_type) != rx_shift[7])) begin
            rx_parity_err <= 1'b1;
        end else if (cfg_parity_en && (calc_parity(rx_shift[7:0], cfg_parity_type) == rx_shift[7])) begin
            rx_parity_err <= 1'b0;
        end else if (!cfg_parity_en) begin
            rx_parity_err <= 1'b0;
        end

        if (DYNAMIC_CONFIG) begin
            tx_parity_reg <= calc_parity(tx_data, cfg_parity_type);
        end
    end
end

generate
    if (DYNAMIC_CONFIG) begin : dynamic_cfg
        assign tx_parity = tx_parity_reg;
    end else begin : fixed_cfg
        parameter FIXED_TYPE = 0;
        assign tx_parity = ^tx_data ^ FIXED_TYPE;
    end
endgenerate

endmodule