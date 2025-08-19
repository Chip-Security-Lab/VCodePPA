//SystemVerilog
//-----------------------------------------------------------------------------
// Package: timer_pkg
// Description: Package containing common parameters and types
// Standard: IEEE 1364-2005
//-----------------------------------------------------------------------------
package timer_pkg;
    // FSM state definition
    typedef enum logic {
        IDLE     = 1'b0,
        COUNTING = 1'b1
    } timer_state_t;
    
    // Default counter parameters
    parameter COUNTER_WIDTH = 8;
    parameter COUNTER_INIT_VALUE = 100;
    
    // Timing control parameters
    parameter CLK_DOMAIN_CROSSING_SYNC_STAGES = 2;
endpackage

//-----------------------------------------------------------------------------
// Module: Timer_FSM_Control (Top-level module)
// Description: Controls a timer with trigger input and done output
// Standard: IEEE 1364-2005
//-----------------------------------------------------------------------------
module Timer_FSM_Control #(
    parameter CNT_WIDTH = timer_pkg::COUNTER_WIDTH,
    parameter INIT_VALUE = timer_pkg::COUNTER_INIT_VALUE
) (
    input  wire                clk,
    input  wire                rst,
    input  wire                trigger,
    output wire                done
);

    // Interface signals between modules
    wire                       timer_state;
    wire                       load_counter;
    wire                       decrement_counter;
    wire [CNT_WIDTH-1:0]       counter_value;
    wire                       counter_is_zero;
    wire                       counter_is_one;

    // Instantiate Control Module
    Timer_Control_Unit #(
        .CNT_WIDTH             (CNT_WIDTH)
    ) u_control (
        .clk                   (clk),
        .rst                   (rst),
        .trigger               (trigger),
        .counter_is_zero       (counter_is_zero),
        .counter_is_one        (counter_is_one),
        .state                 (timer_state),
        .load_counter          (load_counter),
        .decrement_counter     (decrement_counter)
    );
    
    // Instantiate Timer Datapath Module
    Timer_Datapath #(
        .CNT_WIDTH             (CNT_WIDTH),
        .INIT_VALUE            (INIT_VALUE)
    ) u_datapath (
        .clk                   (clk),
        .rst                   (rst),
        .load_counter          (load_counter),
        .decrement_counter     (decrement_counter),
        .counter_value         (counter_value),
        .counter_is_zero       (counter_is_zero),
        .counter_is_one        (counter_is_one),
        .done                  (done)
    );

endmodule

//-----------------------------------------------------------------------------
// Module: Timer_Control_Unit
// Description: FSM controller for timer operations
//-----------------------------------------------------------------------------
module Timer_Control_Unit #(
    parameter CNT_WIDTH = timer_pkg::COUNTER_WIDTH
) (
    input  wire                clk,
    input  wire                rst,
    input  wire                trigger,
    input  wire                counter_is_zero,
    input  wire                counter_is_one,
    output reg                 state,
    output reg                 load_counter,
    output reg                 decrement_counter
);

    import timer_pkg::*;
    
    // Next state logic
    reg next_state;
    
    // State transition logic
    always_comb begin
        case(state)
            IDLE: next_state = trigger ? COUNTING : IDLE;
            COUNTING: next_state = counter_is_zero ? IDLE : COUNTING;
            default: next_state = IDLE;
        endcase
    end

    // State register
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Control signals generation
    always_comb begin
        // Default values
        load_counter = 1'b0;
        decrement_counter = 1'b0;
        
        case(state)
            IDLE: begin
                if (trigger) load_counter = 1'b1;
            end
            COUNTING: begin
                decrement_counter = 1'b1;
            end
        endcase
    end

endmodule

//-----------------------------------------------------------------------------
// Module: Timer_Datapath
// Description: Datapath containing counter and output logic
//-----------------------------------------------------------------------------
module Timer_Datapath #(
    parameter CNT_WIDTH = timer_pkg::COUNTER_WIDTH,
    parameter INIT_VALUE = timer_pkg::COUNTER_INIT_VALUE
) (
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 load_counter,
    input  wire                 decrement_counter,
    output reg  [CNT_WIDTH-1:0] counter_value,
    output wire                 counter_is_zero,
    output wire                 counter_is_one,
    output reg                  done
);

    // Counter module instantiation
    Counter_Module #(
        .CNT_WIDTH              (CNT_WIDTH),
        .INIT_VALUE             (INIT_VALUE)
    ) u_counter (
        .clk                    (clk),
        .rst                    (rst),
        .load_counter           (load_counter),
        .decrement_counter      (decrement_counter),
        .counter_value          (counter_value),
        .counter_is_zero        (counter_is_zero),
        .counter_is_one         (counter_is_one)
    );
    
    // Output generation logic
    Output_Generator u_output_gen (
        .clk                    (clk),
        .rst                    (rst),
        .counter_is_one         (counter_is_one),
        .done                   (done)
    );

endmodule

//-----------------------------------------------------------------------------
// Module: Counter_Module
// Description: Parametrized down-counter with status flags
//-----------------------------------------------------------------------------
module Counter_Module #(
    parameter CNT_WIDTH = timer_pkg::COUNTER_WIDTH,
    parameter INIT_VALUE = timer_pkg::COUNTER_INIT_VALUE
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  load_counter,
    input  wire                  decrement_counter,
    output reg   [CNT_WIDTH-1:0] counter_value,
    output wire                  counter_is_zero,
    output wire                  counter_is_one
);

    // Optimize with registered compare values to improve timing
    reg counter_is_zero_reg, counter_is_one_reg;
    
    // Counter logic with optimized structure for better timing
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_value <= {CNT_WIDTH{1'b0}};
        end else if (load_counter) begin
            counter_value <= INIT_VALUE[CNT_WIDTH-1:0];
        end else if (decrement_counter && !counter_is_zero) begin
            counter_value <= counter_value - 1'b1;
        end
    end
    
    // Pre-compute comparison results for zero latency
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_is_zero_reg <= 1'b1;
            counter_is_one_reg <= 1'b0;
        end else if (load_counter) begin
            counter_is_zero_reg <= (INIT_VALUE == 0);
            counter_is_one_reg <= (INIT_VALUE == 1);
        end else if (decrement_counter) begin
            counter_is_zero_reg <= (counter_value == 1) || counter_is_zero;
            counter_is_one_reg <= (counter_value == 2);
        end
    end
    
    // Status flags - use registered values for better timing
    assign counter_is_zero = counter_is_zero_reg;
    assign counter_is_one = counter_is_one_reg;

endmodule

//-----------------------------------------------------------------------------
// Module: Output_Generator
// Description: Generates the done output signal
//-----------------------------------------------------------------------------
module Output_Generator (
    input  wire clk,
    input  wire rst,
    input  wire counter_is_one,
    output reg  done
);

    // Add synchronization stage for better timing
    reg counter_is_one_sync;
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_is_one_sync <= 1'b0;
            done <= 1'b0;
        end else begin
            counter_is_one_sync <= counter_is_one;
            done <= counter_is_one_sync;
        end
    end

endmodule