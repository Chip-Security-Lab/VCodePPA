//SystemVerilog
module edge_pulse_gen(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire signal_in,
    output wire valid_out,
    output wire pulse_out,
    output wire ready_out
);
    // Stage 1 registers
    reg signal_d_stage1;
    reg valid_stage1;
    reg signal_in_stage1;
    
    // Stage 2 registers
    reg pulse_out_reg;
    reg valid_stage2;
    
    // Ready signal - always ready to accept new data in this design
    assign ready_out = 1'b1;
    
    // Stage 1: Capture input and delay signal
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            signal_d_stage1 <= 1'b0;
            signal_in_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            signal_d_stage1 <= signal_in;
            signal_in_stage1 <= signal_in;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Generate pulse and propagate valid signal
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            pulse_out_reg <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            pulse_out_reg <= signal_in_stage1 & ~signal_d_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output assignments
    assign pulse_out = pulse_out_reg;
    assign valid_out = valid_stage2;
    
endmodule