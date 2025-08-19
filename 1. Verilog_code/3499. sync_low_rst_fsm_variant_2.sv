//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: sync_low_rst_fsm_top.v
// Description: Top-level module for synchronous low-reset FSM with pipelined logic
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module sync_low_rst_fsm_top (
    input  wire clk,      // System clock
    input  wire rst_n,    // Active-low reset
    input  wire trigger,  // State transition trigger
    output wire state_out // Output indicating active state
);

    // Internal signals for module interconnection
    wire current_state;
    wire next_state;
    wire next_state_pipelined;
    
    // Instantiate state register module
    fsm_state_register u_state_register (
        .clk          (clk),
        .rst_n        (rst_n),
        .next_state   (next_state_pipelined),
        .current_state(current_state)
    );
    
    // Instantiate next state logic module
    fsm_next_state_logic u_next_state_logic (
        .clk          (clk),
        .rst_n        (rst_n),
        .current_state(current_state),
        .trigger      (trigger),
        .next_state   (next_state),
        .next_state_pipelined(next_state_pipelined)
    );
    
    // Instantiate output decoder module
    fsm_output_decoder u_output_decoder (
        .clk          (clk),
        .rst_n        (rst_n),
        .current_state(current_state),
        .state_out    (state_out)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: fsm_state_register.v
// Description: State register module for the FSM
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module fsm_state_register (
    input  wire clk,           // System clock
    input  wire rst_n,         // Active-low reset
    input  wire next_state,    // Next state input
    output reg  current_state  // Current state output
);

    // State encoding
    localparam IDLE = 1'b0;
    
    // State register with synchronous reset
    always @(posedge clk) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: fsm_next_state_logic.v
// Description: Next state logic module for the FSM with pipelining
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module fsm_next_state_logic (
    input  wire clk,           // System clock
    input  wire rst_n,         // Active-low reset
    input  wire current_state, // Current state input
    input  wire trigger,       // State transition trigger
    output reg  next_state,    // Intermediate next state output
    output reg  next_state_pipelined // Pipelined next state output
);

    // State encoding
    localparam IDLE = 1'b0;
    localparam ACTIVE = 1'b1;
    
    // Registered signals for trigger (pipeline stage 1)
    reg trigger_reg;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            trigger_reg <= 1'b0;
        end else begin
            trigger_reg <= trigger;
        end
    end
    
    // Combinational next state logic
    always @(*) begin
        case(current_state)
            IDLE: begin
                if (trigger_reg) begin
                    next_state = ACTIVE;
                end else begin
                    next_state = IDLE;
                end
            end
            ACTIVE: begin
                if (trigger_reg) begin
                    next_state = ACTIVE;
                end else begin
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Pipeline register for next state (pipeline stage 2)
    always @(posedge clk) begin
        if (!rst_n) begin
            next_state_pipelined <= IDLE;
        end else begin
            next_state_pipelined <= next_state;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: fsm_output_decoder.v
// Description: Output decoder module for the FSM with pipelined output
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module fsm_output_decoder (
    input  wire clk,           // System clock
    input  wire rst_n,         // Active-low reset
    input  wire current_state, // Current state input
    output reg  state_out      // Pipelined output indicating active state
);

    // State encoding
    localparam ACTIVE = 1'b1;
    
    // Intermediate output signal
    reg state_out_comb;
    
    // Combinational output logic
    always @(*) begin
        if (current_state == ACTIVE) begin
            state_out_comb = 1'b1;
        end else begin
            state_out_comb = 1'b0;
        end
    end
    
    // Register output to create pipeline stage
    always @(posedge clk) begin
        if (!rst_n) begin
            state_out <= 1'b0;
        end else begin
            state_out <= state_out_comb;
        end
    end

endmodule