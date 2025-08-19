//SystemVerilog
module tff_pulse (
    input  logic clk,      // Clock input
    input  logic rstn,     // Active-low reset
    input  logic t,        // Toggle control input
    input  logic valid_in, // Input valid signal
    output logic q,        // Toggle flip-flop output
    output logic valid_out // Output valid signal
);

    // Pipeline stage 1 - Input capture registers
    logic t_stage1;
    logic valid_stage1;
    
    // Pipeline stage 2 - Toggle computation
    logic q_next_stage2;
    logic valid_stage2;
    
    // Pipeline stage 1 logic - Reset handling
    always_ff @(posedge clk) begin
        if (!rstn) begin
            t_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            t_stage1 <= t;
            valid_stage1 <= valid_in;
        end
    end
    
    // Pipeline stage 2 - Toggle computation
    always_ff @(posedge clk) begin
        if (!rstn) begin
            q_next_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            q_next_stage2 <= t_stage1 ? ~q : q;
        end
    end
    
    // Pipeline stage 2 - Valid signal propagation
    always_ff @(posedge clk) begin
        if (!rstn) begin
            valid_stage2 <= 1'b0;
        end
        else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage - Output register update
    always_ff @(posedge clk) begin
        if (!rstn) begin
            q <= 1'b0;
        end
        else if (valid_stage2) begin
            q <= q_next_stage2;
        end
    end
    
    // Output stage - Valid signal propagation
    always_ff @(posedge clk) begin
        if (!rstn) begin
            valid_out <= 1'b0;
        end
        else begin
            valid_out <= valid_stage2;
        end
    end

endmodule