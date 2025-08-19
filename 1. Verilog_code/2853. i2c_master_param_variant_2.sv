//SystemVerilog
module i2c_master_param #(
    parameter CLK_FREQ = 50_000_000,
    parameter I2C_FREQ = 100_000
)(
    input wire clk_in, reset_n,
    input wire [7:0] data_tx,
    input wire [6:0] slave_addr,
    input wire rw, enable,
    output reg [7:0] data_rx,
    output reg done, error,
    inout wire scl, sda
);
    localparam DIVIDER = (CLK_FREQ/I2C_FREQ)/4;
    reg [15:0] clk_cnt;
    reg sda_out_int, scl_out_int, sda_control_int;
    reg [3:0] state, state_buf;
    reg enable_buf;
    reg scl_out_buf;
    reg sda_out_buf;
    reg sda_control_buf;

    // First stage buffer for high fanout signals
    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            enable_buf <= 1'b0;
            state_buf <= 4'h0;
            scl_out_buf <= 1'b1;
            sda_out_buf <= 1'b1;
            sda_control_buf <= 1'b1;
        end else begin
            enable_buf <= enable;
            state_buf <= state;
            scl_out_buf <= scl_out_int;
            sda_out_buf <= sda_out_int;
            sda_control_buf <= sda_control_int;
        end
    end

    // Output buffer assignments, driving IOs with buffered signals
    assign scl = (scl_out_buf) ? 1'bz : 1'b0;
    assign sda = (sda_control_buf) ? 1'bz : sda_out_buf;

    // Main state machine with buffered 'enable' and 'state'
    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            state <= 4'h0;
            sda_out_int <= 1'b1;
            scl_out_int <= 1'b1;
            sda_control_int <= 1'b1;
            data_rx <= 8'h00;
            done <= 1'b0;
            error <= 1'b0;
            clk_cnt <= 16'h0;
        end else begin
            case(state)
                4'h0: begin
                    done <= 1'b0;
                    error <= 1'b0;
                    if (enable_buf) begin
                        state <= 4'h1;
                    end
                end
                // ... (Here would be the rest of the state machine, not shown in original code)
                default: state <= 4'h0;
            endcase
        end
    end

endmodule