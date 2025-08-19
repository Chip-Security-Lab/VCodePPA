//SystemVerilog
// Top level module
module wave11_piecewise #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    output wire [WIDTH-1:0] wave_out
);
    // Internal connections
    wire [3:0] state;
    wire state_reset;

    // State controller module instance
    state_controller #(
        .MAX_STATE(4'd4)
    ) state_ctrl_inst (
        .clk        (clk),
        .rst        (rst),
        .state      (state),
        .state_reset(state_reset)
    );

    // Wave generator module instance
    wave_generator #(
        .WIDTH(WIDTH)
    ) wave_gen_inst (
        .clk      (clk),
        .rst      (rst),
        .state    (state),
        .wave_out (wave_out)
    );

endmodule

// State controller module
module state_controller #(
    parameter MAX_STATE = 4'd4
)(
    input  wire       clk,
    input  wire       rst,
    output reg  [3:0] state,
    output wire       state_reset
);
    // State reset signal indicates when state counter loops back
    assign state_reset = (state == MAX_STATE);

    // State counter logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 4'd0;
        end else begin
            if (state < MAX_STATE) 
                state <= state + 1'b1;
            else
                state <= 4'd0;
        end
    end
endmodule

// Wave generator module
module wave_generator #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [3:0]       state,
    output reg  [WIDTH-1:0] wave_out
);
    // Wave output lookup table
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wave_out <= {WIDTH{1'b0}};
        end else begin
            case (state)
                4'd0 : wave_out <= 8'd10;
                4'd1 : wave_out <= 8'd50;
                4'd2 : wave_out <= 8'd100;
                4'd3 : wave_out <= 8'd150;
                default: wave_out <= 8'd200;
            endcase
        end
    end
endmodule