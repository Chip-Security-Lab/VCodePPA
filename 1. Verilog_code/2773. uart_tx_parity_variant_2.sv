//SystemVerilog
// Top-level UART TX with parity module
module uart_tx_parity #(
    parameter DWIDTH = 8
) (
    input  wire              clk,
    input  wire              rst_n,
    input  wire              tx_en,
    input  wire [DWIDTH-1:0] data_in,
    input  wire [1:0]        parity_mode, // 00:none, 01:odd, 10:even
    output wire              tx_out,
    output wire              tx_active
);

    // Internal signals
    wire                     ctrl_tx_out;
    wire                     ctrl_tx_active;
    wire                     ctrl_shift_en;
    wire                     ctrl_load_data;
    wire                     ctrl_load_parity;
    wire [2:0]               ctrl_state;
    wire [3:0]               ctrl_bit_index;
    wire                     parity_bit;
    wire [DWIDTH-1:0]        shift_data_out;

    // FSM and control logic submodule
    uart_tx_ctrl #(
        .DWIDTH(DWIDTH)
    ) u_ctrl (
        .clk           (clk),
        .rst_n         (rst_n),
        .tx_en         (tx_en),
        .parity_mode   (parity_mode),
        .data_in       (data_in),
        .parity_bit    (parity_bit),
        .shift_data_in (shift_data_out),
        .tx_out        (ctrl_tx_out),
        .tx_active     (ctrl_tx_active),
        .shift_en      (ctrl_shift_en),
        .load_data     (ctrl_load_data),
        .load_parity   (ctrl_load_parity),
        .state         (ctrl_state),
        .bit_index     (ctrl_bit_index)
    );

    // Data shift register submodule
    uart_tx_shiftreg #(
        .DWIDTH(DWIDTH)
    ) u_shiftreg (
        .clk        (clk),
        .rst_n      (rst_n),
        .load       (ctrl_load_data),
        .shift_en   (ctrl_shift_en),
        .data_in    (data_in),
        .data_out   (shift_data_out)
    );

    // Parity generator submodule
    uart_tx_parity_gen #(
        .DWIDTH(DWIDTH)
    ) u_parity_gen (
        .data        (data_in),
        .parity_mode (parity_mode),
        .parity      (parity_bit)
    );

    assign tx_out    = ctrl_tx_out;
    assign tx_active = ctrl_tx_active;

endmodule

//-----------------------------------------------------------------------------
// UART TX FSM and control logic
//-----------------------------------------------------------------------------
module uart_tx_ctrl #(
    parameter DWIDTH = 8
) (
    input  wire              clk,
    input  wire              rst_n,
    input  wire              tx_en,
    input  wire [1:0]        parity_mode,
    input  wire [DWIDTH-1:0] data_in,
    input  wire              parity_bit,
    input  wire [DWIDTH-1:0] shift_data_in,
    output reg               tx_out,
    output reg               tx_active,
    output reg               shift_en,
    output reg               load_data,
    output reg               load_parity,
    output reg [2:0]         state,
    output reg [3:0]         bit_index
);
    // State encoding
    localparam IDLE      = 3'd0;
    localparam START_BIT = 3'd1;
    localparam DATA_BITS = 3'd2;
    localparam PARITY_BIT= 3'd3;
    localparam STOP_BIT  = 3'd4;

    reg [DWIDTH-1:0] data_reg;
    reg              parity_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            tx_out     <= 1'b1;
            tx_active  <= 1'b0;
            bit_index  <= 4'd0;
            shift_en   <= 1'b0;
            load_data  <= 1'b0;
            load_parity<= 1'b0;
            data_reg   <= {DWIDTH{1'b0}};
            parity_reg <= 1'b0;
        end else begin
            // Default assignments
            shift_en    <= 1'b0;
            load_data   <= 1'b0;
            load_parity <= 1'b0;

            case (state)
                IDLE: begin
                    tx_out    <= 1'b1;
                    tx_active <= 1'b0;
                    if (tx_en) begin
                        load_data   <= 1'b1;
                        load_parity <= 1'b1;
                        state       <= START_BIT;
                        tx_active   <= 1'b1;
                        bit_index   <= 4'd0;
                    end
                end
                START_BIT: begin
                    tx_out    <= 1'b0;
                    state     <= DATA_BITS;
                end
                DATA_BITS: begin
                    tx_out    <= shift_data_in[0];
                    shift_en  <= 1'b1;
                    if (bit_index < DWIDTH-1) begin
                        bit_index <= bit_index + 1'b1;
                    end else begin
                        bit_index <= 4'd0;
                        if (parity_mode == 2'b00)
                            state <= STOP_BIT;
                        else
                            state <= PARITY_BIT;
                    end
                end
                PARITY_BIT: begin
                    tx_out    <= parity_bit;
                    state     <= STOP_BIT;
                end
                STOP_BIT: begin
                    tx_out    <= 1'b1;
                    tx_active <= 1'b0;
                    state     <= IDLE;
                end
                default: begin
                    state     <= IDLE;
                    tx_out    <= 1'b1;
                    tx_active <= 1'b0;
                end
            endcase
        end
    end
endmodule

//-----------------------------------------------------------------------------
// UART TX Data Shift Register
//-----------------------------------------------------------------------------
module uart_tx_shiftreg #(
    parameter DWIDTH = 8
) (
    input  wire              clk,
    input  wire              rst_n,
    input  wire              load,
    input  wire              shift_en,
    input  wire [DWIDTH-1:0] data_in,
    output reg  [DWIDTH-1:0] data_out
);
    // Shift register for serializing data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {DWIDTH{1'b0}};
        else if (load)
            data_out <= data_in;
        else if (shift_en)
            data_out <= {1'b0, data_out[DWIDTH-1:1]};
    end
endmodule

//-----------------------------------------------------------------------------
// UART TX Parity Generator
//-----------------------------------------------------------------------------
module uart_tx_parity_gen #(
    parameter DWIDTH = 8
) (
    input  wire [DWIDTH-1:0] data,
    input  wire [1:0]        parity_mode, // 00:none, 01:odd, 10:even
    output reg               parity
);
    // Parity calculation logic
    always @(*) begin
        case (parity_mode)
            2'b01: parity = ~(^data); // Odd parity
            2'b10: parity = (^data);  // Even parity
            default: parity = 1'b0;   // No parity (not used)
        endcase
    end
endmodule