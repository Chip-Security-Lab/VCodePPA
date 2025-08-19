//SystemVerilog
// Top-level UART with Programmable Parity
module UART_ProgrammableParity #(
    parameter DYNAMIC_CONFIG = 1
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        cfg_parity_en,    // Parity enable
    input  wire        cfg_parity_type,  // 0-odd, 1-even
    input  wire [7:0]  tx_payload,
    output wire [7:0]  rx_payload,
    input  wire [7:0]  rx_shift,
    output wire        rx_parity_err,
    output wire        tx_parity
);

    // Internal signals
    wire        parity_en_pipe;
    wire [7:0]  tx_data_pipe;
    wire [7:0]  rx_payload_pipe;
    wire        rx_parity_err_pipe;
    wire        tx_parity_pipe;

    // Parity control and RX logic
    UART_ParityControl u_parity_ctrl (
        .clk            (clk),
        .rst_n          (rst_n),
        .cfg_parity_en  (cfg_parity_en),
        .cfg_parity_type(cfg_parity_type),
        .tx_payload     (tx_payload),
        .rx_shift       (rx_shift),
        .parity_en_out  (parity_en_pipe),
        .tx_data_out    (tx_data_pipe),
        .rx_payload_out (rx_payload_pipe),
        .rx_parity_err  (rx_parity_err_pipe)
    );

    // Parity generator for TX
    UART_ParityGen #(
        .DYNAMIC_CONFIG (DYNAMIC_CONFIG)
    ) u_parity_gen (
        .clk            (clk),
        .rst_n          (rst_n),
        .tx_data        (tx_data_pipe),
        .cfg_parity_type(cfg_parity_type),
        .tx_parity      (tx_parity_pipe)
    );

    // Output assignments
    assign rx_parity_err = rx_parity_err_pipe;
    assign rx_payload    = rx_payload_pipe;
    assign tx_parity     = tx_parity_pipe;

endmodule

//-----------------------------------------------------------------------------
// Parity Control and RX Logic Module (Retimed: Registers moved after combinational logic)
//-----------------------------------------------------------------------------
module UART_ParityControl (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        cfg_parity_en,
    input  wire        cfg_parity_type,
    input  wire [7:0]  tx_payload,
    input  wire [7:0]  rx_shift,
    output reg         parity_en_out,
    output reg  [7:0]  tx_data_out,
    output reg  [7:0]  rx_payload_out,
    output reg         rx_parity_err
);

    // Combinational logic signals before registers (forward retiming)
    wire        parity_en_comb;
    wire [7:0]  tx_data_comb;
    wire [7:0]  rx_payload_comb;
    wire        rx_parity_err_comb;
    wire        rx_parity_calc;

    // Parity calculation for RX (combinational)
    UART_ParityCalc u_rx_parity_calc (
        .data        (rx_shift[7:0]),
        .parity_type (cfg_parity_type),
        .parity_bit  (rx_parity_calc)
    );

    // Combinational assignments (formerly inside always block)
    assign parity_en_comb  = cfg_parity_en;
    assign tx_data_comb    = tx_payload;
    assign rx_payload_comb = rx_shift[7:0];
    assign rx_parity_err_comb = cfg_parity_en ? (rx_parity_calc != rx_shift[7]) : 1'b0;

    // Registering after combinational logic (retimed registers)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_en_out  <= 1'b0;
            tx_data_out    <= 8'b0;
            rx_payload_out <= 8'b0;
            rx_parity_err  <= 1'b0;
        end else begin
            parity_en_out  <= parity_en_comb;
            tx_data_out    <= tx_data_comb;
            rx_payload_out <= rx_payload_comb;
            rx_parity_err  <= rx_parity_err_comb;
        end
    end

endmodule

//-----------------------------------------------------------------------------
// Parity Generator for TX Module (No change, register already after logic)
//-----------------------------------------------------------------------------
module UART_ParityGen #(
    parameter DYNAMIC_CONFIG = 1
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  tx_data,
    input  wire        cfg_parity_type,
    output wire        tx_parity
);

generate
    if (DYNAMIC_CONFIG) begin : gen_dynamic
        reg tx_parity_reg;
        wire tx_parity_calc;
        UART_ParityCalc u_tx_parity_calc (
            .data        (tx_data),
            .parity_type (cfg_parity_type),
            .parity_bit  (tx_parity_calc)
        );
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                tx_parity_reg <= 1'b0;
            end else begin
                tx_parity_reg <= tx_parity_calc;
            end
        end
        assign tx_parity = tx_parity_reg;
    end else begin : gen_fixed
        parameter FIXED_TYPE = 0;
        assign tx_parity = ^tx_data ^ FIXED_TYPE;
    end
endgenerate

endmodule

//-----------------------------------------------------------------------------
// Parity Calculation Module (Reusable)
//-----------------------------------------------------------------------------
module UART_ParityCalc (
    input  wire [7:0] data,
    input  wire       parity_type,
    output wire       parity_bit
);
    wire sum;
    assign sum = ^data;
    assign parity_bit = (parity_type) ? ~sum : sum;
endmodule