//SystemVerilog
module UART_ProgrammableParity #(
    parameter DYNAMIC_CONFIG = 1
)(
    input  wire        clk,
    input  wire        rst_n,  
    input  wire        cfg_parity_en,
    input  wire        cfg_parity_type,
    input  wire [7:0]  tx_payload,
    output reg  [7:0]  rx_payload, 
    input  wire [7:0]  rx_shift,   
    output reg         rx_parity_err,    
    output wire        tx_parity
);

// ------------------- Pipeline Stage 1 (Merged) -------------------
// Capture inputs, calculate parity, and register outputs

reg        parity_en_stage1;
reg        parity_type_stage1;
reg [7:0]  tx_data_stage1;
reg [7:0]  rx_shift_stage1;
reg        tx_parity_stage1;
reg        rx_parity_calc_stage1;
reg [7:0]  rx_payload_stage1;
reg        rx_parity_err_stage1;
reg        valid_stage1;

function calc_parity;
    input [7:0] data;
    input parity_type;
    reg sum;
    begin
        sum = ^data;
        calc_parity = (parity_type) ? ~sum : sum;
    end
endfunction

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        parity_en_stage1      <= 1'b0;
        parity_type_stage1    <= 1'b0;
        tx_data_stage1        <= 8'd0;
        rx_shift_stage1       <= 8'd0;
        tx_parity_stage1      <= 1'b0;
        rx_parity_calc_stage1 <= 1'b0;
        rx_payload_stage1     <= 8'd0;
        rx_parity_err_stage1  <= 1'b0;
        valid_stage1          <= 1'b0;
    end else begin
        parity_en_stage1      <= cfg_parity_en;
        parity_type_stage1    <= cfg_parity_type;
        tx_data_stage1        <= tx_payload;
        rx_shift_stage1       <= rx_shift;
        tx_parity_stage1      <= calc_parity(tx_payload, cfg_parity_type);
        rx_parity_calc_stage1 <= calc_parity(rx_shift[7:0], cfg_parity_type);
        rx_payload_stage1     <= rx_shift;
        if (cfg_parity_en) begin
            rx_parity_err_stage1 <= (calc_parity(rx_shift[7:0], cfg_parity_type) != rx_shift[7]);
        end else begin
            rx_parity_err_stage1 <= 1'b0;
        end
        valid_stage1          <= 1'b1;
    end
end

// ------------------- Output Assignments -------------------

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_payload    <= 8'd0;
        rx_parity_err <= 1'b0;
    end else if (valid_stage1) begin
        rx_payload    <= rx_payload_stage1;
        rx_parity_err <= rx_parity_err_stage1;
    end
end

generate
    if (DYNAMIC_CONFIG) begin : dynamic_cfg
        assign tx_parity = tx_parity_stage1;
    end else begin : fixed_cfg
        parameter FIXED_TYPE = 0;
        assign tx_parity = ^tx_parity_stage1 ^ FIXED_TYPE;
    end
endgenerate

endmodule