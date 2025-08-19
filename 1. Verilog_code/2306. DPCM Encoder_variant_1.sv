//SystemVerilog
//IEEE 1364-2005 Verilog standard
module dpcm_encoder (
    input            clock,
    input            reset_n,
    input      [7:0] sample_in,
    input            sample_valid,
    output     [7:0] dpcm_out,
    output           dpcm_valid,
    output     [7:0] predicted_value
);
    // Internal signals for interconnecting submodules
    wire [7:0] prediction;
    wire [7:0] previous_sample;
    wire [1:0] state;
    wire [1:0] next_state;
    wire [7:0] next_predicted_value;
    wire [7:0] next_dpcm_out;

    // State controller submodule
    state_controller state_ctrl (
        .clock        (clock),
        .reset_n      (reset_n),
        .sample_valid (sample_valid),
        .state        (state),
        .next_state   (next_state)
    );

    // Prediction generator submodule
    prediction_generator pred_gen (
        .previous_sample      (previous_sample),
        .prediction           (prediction),
        .next_predicted_value (next_predicted_value)
    );

    // Differential encoder submodule
    differential_encoder diff_enc (
        .sample_in     (sample_in),
        .prediction    (prediction),
        .next_dpcm_out (next_dpcm_out)
    );

    // Output register control submodule
    output_controller out_ctrl (
        .clock               (clock),
        .state               (state),
        .next_state          (next_state),
        .sample_in           (sample_in),
        .next_dpcm_out       (next_dpcm_out),
        .next_predicted_value(next_predicted_value),
        .previous_sample     (previous_sample),
        .predicted_value     (predicted_value),
        .dpcm_out            (dpcm_out),
        .dpcm_valid          (dpcm_valid)
    );
endmodule

//State controller module
module state_controller (
    input        clock,
    input        reset_n,
    input        sample_valid,
    output [1:0] state,
    output [1:0] next_state
);
    // Control state encoding - one-hot encoding for better PPA
    localparam RESET_STATE = 2'b01,
               SAMPLE_VALID = 2'b10;
    
    reg [1:0] state_reg;
    reg [1:0] next_state_reg;
    
    assign state = state_reg;
    assign next_state = next_state_reg;
    
    // Combinational next state logic
    always @(*) begin
        if (!reset_n) 
            next_state_reg = RESET_STATE;
        else if (sample_valid)
            next_state_reg = SAMPLE_VALID;
        else
            next_state_reg = 2'b00; // IDLE state
    end
    
    // Sequential state update
    always @(posedge clock) begin
        state_reg <= next_state_reg;
    end
endmodule

//Prediction generator module
module prediction_generator (
    input  [7:0] previous_sample,
    output [7:0] prediction,
    output [7:0] next_predicted_value
);
    // Simple predictor - uses previous sample as prediction
    assign prediction = previous_sample;
    assign next_predicted_value = prediction;
endmodule

//Differential encoder module
module differential_encoder (
    input  [7:0] sample_in,
    input  [7:0] prediction,
    output [7:0] next_dpcm_out
);
    // Calculate difference between input and prediction
    assign next_dpcm_out = sample_in - prediction;
endmodule

//Output controller module
module output_controller (
    input        clock,
    input  [1:0] state,
    input  [1:0] next_state,
    input  [7:0] sample_in,
    input  [7:0] next_dpcm_out,
    input  [7:0] next_predicted_value,
    output [7:0] previous_sample,
    output [7:0] predicted_value,
    output [7:0] dpcm_out,
    output       dpcm_valid
);
    // Control state encoding - one-hot encoding for better PPA
    localparam RESET_STATE = 2'b01,
               SAMPLE_VALID = 2'b10;
    
    reg [7:0] previous_sample_reg;
    reg [7:0] predicted_value_reg;
    reg [7:0] dpcm_out_reg;
    reg       dpcm_valid_reg;
    
    assign previous_sample = previous_sample_reg;
    assign predicted_value = predicted_value_reg;
    assign dpcm_out = dpcm_out_reg;
    assign dpcm_valid = dpcm_valid_reg;
    
    // Sequential output register logic
    always @(posedge clock) begin
        case (state)
            RESET_STATE: begin
                previous_sample_reg <= 8'h80; // Mid-level
                predicted_value_reg <= 8'h80;
                dpcm_out_reg <= 8'b0;
                dpcm_valid_reg <= 1'b0;
            end
            
            SAMPLE_VALID: begin
                previous_sample_reg <= sample_in;
                predicted_value_reg <= next_predicted_value;
                dpcm_out_reg <= next_dpcm_out;
                dpcm_valid_reg <= 1'b1;
            end
            
            default: begin
                dpcm_valid_reg <= 1'b0;
            end
        endcase
    end
endmodule