//SystemVerilog
//=============================================================================
// Top-level module: Pipelined Request Queue
// This module instantiates submodules for input registration, queue logic,
// and output registration to create a hierarchical structure.
//=============================================================================
module IVMU_ReqQueue_Pipelined_Hierarchical #(parameter DEPTH = 4) (
    input clk,
    input reset_n, // Active low reset
    input rd_en,
    input [7:0] irq,
    input input_valid, // Signal indicating valid input request
    output [7:0] next_irq,
    output valid_out // Signal indicating valid output data
);

    // Internal wires connecting pipeline stages
    wire rd_en_q1;
    wire [7:0] irq_q1;
    wire valid_q1;

    wire [7:0] queue_head_q2_comb; // Combinatorial read from queue head after update
    wire valid_q2;                 // Registered valid signal after queue stage

    wire [7:0] next_irq_q3;
    wire valid_q3;

    // Stage 1: Input Registration
    // Registers incoming request signals.
    input_stage #(
        .DATA_WIDTH(8)
    ) u_input_stage (
        .clk         (clk),
        .reset_n     (reset_n),
        .rd_en_in    (rd_en),
        .data_in     (irq),
        .valid_in    (input_valid),
        .rd_en_out   (rd_en_q1),
        .data_out    (irq_q1),
        .valid_out   (valid_q1)
    );

    // Stage 2: Queue Logic and State
    // Manages the queue array based on registered inputs.
    queue_logic #(
        .DEPTH      (DEPTH),
        .DATA_WIDTH (8)
    ) u_queue_logic (
        .clk              (clk),
        .reset_n          (reset_n),
        .rd_en_q1         (rd_en_q1),
        .irq_q1           (irq_q1),
        .valid_q1         (valid_q1),
        .queue_head_out   (queue_head_q2_comb), // Combinatorial output
        .valid_q2         (valid_q2)            // Registered output
    );

    // Stage 3: Output Registration
    // Registers the head of the queue and the valid signal from the queue stage.
    output_stage #(
        .DATA_WIDTH(8)
    ) u_output_stage (
        .clk       (clk),
        .reset_n   (reset_n),
        .data_in   (queue_head_q2_comb), // Data from combinatorial read of queue head
        .valid_in  (valid_q2),           // Valid signal from queue stage
        .data_out  (next_irq_q3),
        .valid_out (valid_q3)
    );

    // Final output assignments
    assign next_irq = next_irq_q3;
    assign valid_out = valid_q3;

endmodule

//=============================================================================
// Submodule: input_stage
// Registers the incoming request signals.
//=============================================================================
module input_stage #(parameter DATA_WIDTH = 8) (
    input clk,
    input reset_n,
    input rd_en_in,
    input [DATA_WIDTH-1:0] data_in,
    input valid_in,
    output reg rd_en_out,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out
);

    always @(posedge clk) begin
        if (!reset_n) begin
            rd_en_out <= 1'b0;
            data_out <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            rd_en_out <= rd_en_in;
            data_out <= data_in;
            valid_out <= valid_in;
        end
    end

endmodule

//=============================================================================
// Submodule: queue_logic
// Implements the queue state and update logic.
// Contains the main queue array and performs enqueue/dequeue operations.
// Outputs the head of the queue combinatorially after update.
//=============================================================================
module queue_logic #(parameter DEPTH = 4, parameter DATA_WIDTH = 8) (
    input clk,
    input reset_n,
    input rd_en_q1,  // Registered read enable from stage 1
    input [DATA_WIDTH-1:0] irq_q1, // Registered data from stage 1
    input valid_q1,  // Registered valid from stage 1
    output [DATA_WIDTH-1:0] queue_head_out, // Combinatorial read of queue[0]
    output reg valid_q2     // Registered valid signal for next stage
);

    reg [DATA_WIDTH-1:0] queue [0:DEPTH-1];
    integer i;

    always @(posedge clk) begin
        if (!reset_n) begin
            // Reset queue state
            for (i = 0; i < DEPTH; i = i + 1) begin
                queue[i] <= {DATA_WIDTH{1'b0}};
            end
            valid_q2 <= 1'b0;
        end else begin
            valid_q2 <= valid_q1; // Propagate valid signal from Stage 1

            if (valid_q1) begin // Only update queue if Stage 1 had a valid input
                if (rd_en_q1) begin
                    // Dequeue operation (shift left)
                    for (i = 0; i < DEPTH-1; i = i + 1) begin
                        queue[i] <= queue[i+1];
                    end
                    queue[DEPTH-1] <= {DATA_WIDTH{1'b0}}; // Clear the last element
                end else begin
                    // Enqueue operation (shift right)
                    for (i = DEPTH-1; i > 0; i = i - 1) begin
                        queue[i] <= queue[i-1];
                    end
                    queue[0] <= irq_q1; // Insert new element at the head
                end
            end
            // If valid_q1 is low, the queue state is held (no operation performed).
        end
    end

    // Combinatorial read of the queue head *after* the potential update
    assign queue_head_out = queue[0];

endmodule

//=============================================================================
// Submodule: output_stage
// Registers the final output data and valid signal.
//=============================================================================
module output_stage #(parameter DATA_WIDTH = 8) (
    input clk,
    input reset_n,
    input [DATA_WIDTH-1:0] data_in,
    input valid_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out
);

    always @(posedge clk) begin
        if (!reset_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            data_out <= data_in;
            valid_out <= valid_in;
        end
    end

endmodule