//SystemVerilog
module SequenceDetector #(
    parameter DATA_WIDTH = 8,
    parameter SEQUENCE = 8'b1010_1010
)(
    input clk, rst_n,
    input data_in,
    input enable,
    output reg detected
);

    // State definitions
    localparam IDLE = 1'b0, CHECKING = 1'b1;
    reg current_state, next_state;
    reg [DATA_WIDTH-1:0] shift_reg;

    // State register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else if (enable) begin
            current_state <= next_state;
        end
    end

    // Shift register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
        end else if (enable) begin
            shift_reg <= {shift_reg[DATA_WIDTH-2:0], data_in};
        end
    end

    // Next state logic
    always @(*) begin
        if (!enable) begin
            next_state = IDLE;
        end else if (current_state == IDLE) begin
            next_state = CHECKING;
        end else begin
            next_state = CHECKING;
        end
    end

    // Detection logic
    always @(*) begin
        if (current_state == CHECKING && enable) begin
            detected = (shift_reg == SEQUENCE);
        end else begin
            detected = 1'b0;
        end
    end

endmodule