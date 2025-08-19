//SystemVerilog
// Top level module
module pause_enabled_ring (
    input clk,
    input pause,
    input rst,
    output [3:0] current_state
);
    // Internal connections
    wire [3:0] next_state;
    wire [3:0] state_reg_out;
    
    // Assign output
    assign current_state = state_reg_out;
    
    // State calculation submodule
    state_calculator state_calc_inst (
        .current_state(state_reg_out),
        .pause(pause),
        .next_state(next_state)
    );
    
    // State register submodule
    state_register state_reg_inst (
        .clk(clk),
        .rst(rst),
        .next_state(next_state),
        .current_state(state_reg_out)
    );
endmodule

// State calculation submodule
module state_calculator (
    input [3:0] current_state,
    input pause,
    output [3:0] next_state
);
    // One-hot encoded states
    parameter [3:0] STATE_0 = 4'b0001;
    parameter [3:0] STATE_1 = 4'b0010;
    parameter [3:0] STATE_2 = 4'b0100;
    parameter [3:0] STATE_3 = 4'b1000;

    // Calculate next state based on pause signal
    assign next_state = pause ? current_state :
                        (current_state == STATE_0) ? STATE_1 :
                        (current_state == STATE_1) ? STATE_2 :
                        (current_state == STATE_2) ? STATE_3 :
                        (current_state == STATE_3) ? STATE_0 : STATE_0;
endmodule

// State register submodule
module state_register (
    input clk,
    input rst,
    input [3:0] next_state,
    output reg [3:0] current_state
);
    // One-hot encoded reset state
    parameter [3:0] RESET_STATE = 4'b0001;
    
    // Register with reset
    always @(posedge clk) begin
        if (rst)
            current_state <= RESET_STATE;
        else
            current_state <= next_state;
    end
endmodule