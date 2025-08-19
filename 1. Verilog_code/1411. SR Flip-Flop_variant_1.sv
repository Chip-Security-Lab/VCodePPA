//SystemVerilog
// Top level module
module sr_flip_flop (
    input wire clk,
    input wire s,
    input wire r,
    output wire q
);
    // Internal signals
    wire [1:0] sr_inputs;
    wire next_q;
    
    // Buffered high fanout signals
    wire s_buf1, s_buf2;
    wire [1:0] sr_inputs_buf1, sr_inputs_buf2;
    wire next_q_buf1, next_q_buf2;
    
    // Fanout buffers for s signal
    assign s_buf1 = s;
    assign s_buf2 = s;
    
    // Instantiate submodules
    sr_input_encoder u_encoder (
        .s(s_buf1),
        .r(r),
        .sr_inputs(sr_inputs)
    );
    
    // Fanout buffers for sr_inputs
    assign sr_inputs_buf1 = sr_inputs;
    assign sr_inputs_buf2 = sr_inputs;
    
    sr_next_state_logic u_next_state (
        .sr_inputs(sr_inputs_buf1),
        .current_q(q),
        .next_q(next_q)
    );
    
    // Fanout buffers for next_q
    assign next_q_buf1 = next_q;
    assign next_q_buf2 = next_q;
    
    sr_state_register u_state_reg (
        .clk(clk),
        .next_q(next_q_buf1),
        .q(q)
    );
    
endmodule

// Submodule for encoding the S and R inputs
module sr_input_encoder (
    input wire s,
    input wire r,
    output reg [1:0] sr_inputs
);
    // Registered outputs to reduce fanout loading
    always @(*) begin
        sr_inputs = {s, r};
    end
endmodule

// Submodule for next state logic
module sr_next_state_logic (
    input wire [1:0] sr_inputs,
    input wire current_q,
    output reg next_q
);
    // Registered outputs to reduce fanout loading
    always @(*) begin
        case (sr_inputs)
            2'b00: next_q = current_q; // No change
            2'b01: next_q = 1'b0;      // Reset
            2'b10: next_q = 1'b1;      // Set
            2'b11: next_q = 1'bx;      // Invalid - undefined
        endcase
    end
endmodule

// Submodule for state register
module sr_state_register (
    input wire clk,
    input wire next_q,
    output reg q
);
    // Pipelined to improve timing
    reg next_q_reg;
    
    always @(posedge clk) begin
        next_q_reg <= next_q;
        q <= next_q_reg;
    end
endmodule