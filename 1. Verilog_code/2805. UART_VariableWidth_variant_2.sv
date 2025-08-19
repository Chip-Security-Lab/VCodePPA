//SystemVerilog
// Top-level UART_VariableWidth module with Valid-Ready handshake
module UART_VariableWidth #(
    parameter MAX_WIDTH = 9
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [3:0]            data_width,           // Configurable data width (5-9 bits)
    input  wire [7:0]            rx_data,              
    input  wire                  rx_valid,
    output wire                  rx_ready,
    input  wire [MAX_WIDTH-1:0]  tx_truncated,
    input  wire                  tx_valid,
    output wire                  tx_ready,
    output wire [MAX_WIDTH-1:0]  rx_extended,
    output wire                  rx_extended_valid,
    input  wire                  rx_extended_ready,
    output wire [1:0]            stop_bits,
    output wire                  stop_bits_valid,
    input  wire                  stop_bits_ready
);

    // Internal signals for submodule connections
    wire [MAX_WIDTH-1:0] rx_extended_internal;
    wire                 rx_extended_valid_internal;
    wire                 rx_extended_ready_internal;
    wire [1:0]           stop_bits_internal;
    wire                 stop_bits_valid_internal;
    wire                 stop_bits_ready_internal;

    // Data width extension and truncation logic with handshake
    UART_DataWidthAdapter #(
        .MAX_WIDTH(MAX_WIDTH)
    ) u_datawidth_adapter (
        .clk                (clk),
        .rst_n              (rst_n),
        .data_width         (data_width),
        .rx_data            (rx_data),
        .rx_valid           (rx_valid),
        .rx_ready           (rx_ready),
        .tx_truncated       (tx_truncated),
        .tx_valid           (tx_valid),
        .tx_ready           (tx_ready),
        .rx_extended        (rx_extended_internal),
        .rx_extended_valid  (rx_extended_valid_internal),
        .rx_extended_ready  (rx_extended_ready_internal)
    );

    // Dynamic stop bit generation logic with handshake
    UART_StopBitGen u_stopbit_gen (
        .clk                (clk),
        .rst_n              (rst_n),
        .data_width         (data_width),
        .stop_bits          (stop_bits_internal),
        .stop_bits_valid    (stop_bits_valid_internal),
        .stop_bits_ready    (stop_bits_ready_internal)
    );

    // Output assignments
    assign rx_extended         = rx_extended_internal;
    assign rx_extended_valid   = rx_extended_valid_internal;
    assign rx_extended_ready_internal = rx_extended_ready;

    assign stop_bits           = stop_bits_internal;
    assign stop_bits_valid     = stop_bits_valid_internal;
    assign stop_bits_ready_internal = stop_bits_ready;

endmodule

// -----------------------------------------------------------------------------
// 子模块：数据宽度适配器（带Valid-Ready握手）
// -----------------------------------------------------------------------------
module UART_DataWidthAdapter #(
    parameter MAX_WIDTH = 9
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [3:0]            data_width,
    input  wire [7:0]            rx_data,
    input  wire                  rx_valid,
    output wire                  rx_ready,
    input  wire [MAX_WIDTH-1:0]  tx_truncated,
    input  wire                  tx_valid,
    output wire                  tx_ready,
    output reg  [MAX_WIDTH-1:0]  rx_extended,
    output reg                   rx_extended_valid,
    input  wire                  rx_extended_ready
);

    reg [MAX_WIDTH-1:0] rx_extended_reg;
    reg                 rx_extended_valid_reg;
    reg                 rx_handshake_done;
    reg                 tx_handshake_done;

    // Internal handshake logic
    assign rx_ready = ~rx_extended_valid_reg;
    assign tx_ready = ~rx_extended_valid_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_extended_reg      <= {MAX_WIDTH{1'b0}};
            rx_extended_valid_reg<= 1'b0;
        end else begin
            // If downstream ready, clear valid
            if (rx_extended_valid_reg && rx_extended_ready) begin
                rx_extended_valid_reg <= 1'b0;
            end
            // Accept new data if upstream valid and downstream ready
            if ((rx_valid || tx_valid) && ~rx_extended_valid_reg) begin
                case(data_width)
                    4'd5: rx_extended_reg = {4'b0, rx_data[4:0]};
                    4'd6: rx_extended_reg = {3'b0, rx_data[5:0]};
                    4'd7: rx_extended_reg = {2'b0, rx_data[6:0]};
                    4'd8: rx_extended_reg = {1'b0, rx_data[7:0]};
                    4'd9: rx_extended_reg = tx_truncated;
                    default: rx_extended_reg = {1'b0, rx_data};
                endcase
                rx_extended_valid_reg <= 1'b1;
            end
        end
    end

    assign rx_extended        = rx_extended_reg;
    assign rx_extended_valid  = rx_extended_valid_reg;

endmodule

// -----------------------------------------------------------------------------
// 子模块：停止位生成器（带Valid-Ready握手）
// -----------------------------------------------------------------------------
module UART_StopBitGen (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  data_width,
    output reg  [1:0]  stop_bits,
    output reg         stop_bits_valid,
    input  wire        stop_bits_ready
);

    reg [1:0] stop_bits_reg;
    reg       stop_bits_valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stop_bits_reg       <= 2'd1;
            stop_bits_valid_reg <= 1'b0;
        end else begin
            if (stop_bits_valid_reg && stop_bits_ready) begin
                stop_bits_valid_reg <= 1'b0;
            end
            if (!stop_bits_valid_reg) begin
                if (data_width > 8)
                    stop_bits_reg <= 2'd2;
                else
                    stop_bits_reg <= 2'd1;
                stop_bits_valid_reg <= 1'b1;
            end
        end
    end

    assign stop_bits      = stop_bits_reg;
    assign stop_bits_valid= stop_bits_valid_reg;

endmodule