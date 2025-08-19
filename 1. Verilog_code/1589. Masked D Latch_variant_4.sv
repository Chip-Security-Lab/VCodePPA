//SystemVerilog
// Top level module
module masked_d_latch_top (
    input wire [7:0] d_in,
    input wire [7:0] mask,
    input wire enable,
    output wire [7:0] q_out
);

    // Internal signals
    wire [7:0] masked_data;
    wire [7:0] masked_feedback;
    
    // Data masking module
    data_masker data_mask_inst (
        .d_in(d_in),
        .mask(mask),
        .masked_data(masked_data)
    );
    
    // Feedback masking module  
    feedback_masker feedback_mask_inst (
        .q_out(q_out),
        .mask(mask),
        .masked_feedback(masked_feedback)
    );
    
    // Output register module
    output_register output_reg_inst (
        .masked_data(masked_data),
        .masked_feedback(masked_feedback),
        .enable(enable),
        .q_out(q_out)
    );

endmodule

// Data masking submodule
module data_masker (
    input wire [7:0] d_in,
    input wire [7:0] mask,
    output wire [7:0] masked_data
);
    assign masked_data = d_in & mask;
endmodule

// Feedback masking submodule
module feedback_masker (
    input wire [7:0] q_out,
    input wire [7:0] mask,
    output wire [7:0] masked_feedback
);
    assign masked_feedback = q_out & ~mask;
endmodule

// Output register submodule
module output_register (
    input wire [7:0] masked_data,
    input wire [7:0] masked_feedback,
    input wire enable,
    output reg [7:0] q_out
);
    always @* begin
        if (enable)
            q_out = masked_data | masked_feedback;
    end
endmodule