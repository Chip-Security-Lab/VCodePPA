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

// --- Parity Calculation Functions ---
function calc_parity;
    input [7:0] data;
    input parity_type;
    reg sum;
    reg parity_result;
    begin
        sum = ^data;
        if (parity_type) begin
            parity_result = ~sum;
        end else begin
            parity_result = sum;
        end
        calc_parity = parity_result;
    end
endfunction

// --- Internal Registers ---
reg parity_en_reg;
reg [7:0] tx_data_reg;

// --- Pipeline Registers for Long Combinational Path ---
reg [7:0] rx_shift_reg1;
reg [7:0] rx_shift_reg2;
reg cfg_parity_type_reg1;
reg cfg_parity_type_reg2;
reg cfg_parity_en_reg1;
reg cfg_parity_en_reg2;

// --- Pipeline Register for Parity Calculation ---
reg rx_parity_calc_stage1;
reg rx_parity_calc_stage2;

// --- Initialization and Pipeline Stage 1 ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        parity_en_reg         <= 1'b0;
        tx_data_reg           <= 8'b0;
        rx_payload            <= 8'b0;
        rx_shift_reg1         <= 8'b0;
        cfg_parity_type_reg1  <= 1'b0;
        cfg_parity_en_reg1    <= 1'b0;
    end else begin
        parity_en_reg         <= cfg_parity_en;
        tx_data_reg           <= tx_payload;
        rx_payload            <= rx_shift[7:0];
        rx_shift_reg1         <= rx_shift;
        cfg_parity_type_reg1  <= cfg_parity_type;
        cfg_parity_en_reg1    <= cfg_parity_en;
    end
end

// --- Pipeline Stage 2 ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_shift_reg2         <= 8'b0;
        cfg_parity_type_reg2  <= 1'b0;
        cfg_parity_en_reg2    <= 1'b0;
    end else begin
        rx_shift_reg2         <= rx_shift_reg1;
        cfg_parity_type_reg2  <= cfg_parity_type_reg1;
        cfg_parity_en_reg2    <= cfg_parity_en_reg1;
    end
end

// --- Parity Calculation Pipeline Stage 1 ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_parity_calc_stage1 <= 1'b0;
    end else begin
        rx_parity_calc_stage1 <= calc_parity(rx_shift_reg1[7:0], cfg_parity_type_reg1);
    end
end

// --- Parity Calculation Pipeline Stage 2 and Error Flag ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_parity_calc_stage2 <= 1'b0;
        rx_parity_err         <= 1'b0;
    end else begin
        rx_parity_calc_stage2 <= rx_parity_calc_stage1;
        if (cfg_parity_en_reg2) begin
            if (rx_parity_calc_stage2 != rx_shift_reg2[7]) begin
                rx_parity_err <= 1'b1;
            end else begin
                rx_parity_err <= 1'b0;
            end
        end else begin
            rx_parity_err <= 1'b0;
        end
    end
end

// --- TX Parity Generation with Pipeline Register ---
generate
    if (DYNAMIC_CONFIG) begin : dynamic_cfg
        reg tx_parity_stage1;
        reg tx_parity_stage2;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                tx_parity_stage1 <= 1'b0;
            end else begin
                if (cfg_parity_type) begin
                    tx_parity_stage1 <= ~(^tx_data_reg);
                end else begin
                    tx_parity_stage1 <= (^tx_data_reg);
                end
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                tx_parity_stage2 <= 1'b0;
            end else begin
                tx_parity_stage2 <= tx_parity_stage1;
            end
        end
        assign tx_parity = tx_parity_stage2;
    end else begin : fixed_cfg
        parameter FIXED_TYPE = 0;
        reg parity_stage1;
        reg parity_stage2;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                parity_stage1 <= 1'b0;
            end else begin
                parity_stage1 <= (^tx_data_reg);
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                parity_stage2 <= 1'b0;
            end else begin
                if (FIXED_TYPE) begin
                    parity_stage2 <= ~parity_stage1;
                end else begin
                    parity_stage2 <= parity_stage1;
                end
            end
        end
        assign tx_parity = parity_stage2;
    end
endgenerate

endmodule