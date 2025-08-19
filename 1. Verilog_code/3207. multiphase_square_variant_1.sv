//SystemVerilog
module multiphase_square(
    input wire clock,
    input wire reset_n,
    input wire [7:0] period,
    input wire valid,
    output wire ready,
    output wire [3:0] phase_outputs
);
    // Internal signals
    wire timer_done;
    wire phase_shift_en;
    wire processing;
    
    // Control module for handling valid/ready protocol
    valid_ready_handler u_valid_ready_handler (
        .clock          (clock),
        .reset_n        (reset_n),
        .valid          (valid),
        .timer_done     (timer_done),
        .processing     (processing),
        .ready          (ready),
        .phase_shift_en (phase_shift_en)
    );
    
    // Timer module for generating accurate timing
    period_timer u_timer (
        .clock          (clock),
        .reset_n        (reset_n),
        .period         (period),
        .processing     (processing),
        .timer_done     (timer_done)
    );
    
    // Phase rotation module
    phase_generator u_phase_gen (
        .clock          (clock),
        .reset_n        (reset_n),
        .phase_shift_en (phase_shift_en),
        .phase_outputs  (phase_outputs)
    );
    
endmodule

//------------------------------------------------
// Valid-Ready handler submodule
//------------------------------------------------
module valid_ready_handler (
    input wire clock,
    input wire reset_n,
    input wire valid,
    input wire timer_done,
    output reg processing,
    output reg ready,
    output reg phase_shift_en
);
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            processing <= 1'b0;
            ready <= 1'b1;
            phase_shift_en <= 1'b0;
        end else begin
            // Default values
            phase_shift_en <= 1'b0;
            
            if (valid && ready && !processing) begin
                processing <= 1'b1;
                ready <= 1'b0;
            end
            
            if (processing && timer_done) begin
                processing <= 1'b0;
                ready <= 1'b1;
                phase_shift_en <= 1'b1;
            end
        end
    end
endmodule

//------------------------------------------------
// Period timer submodule
//------------------------------------------------
module period_timer (
    input wire clock,
    input wire reset_n,
    input wire [7:0] period,
    input wire processing,
    output wire timer_done
);
    reg [7:0] count;
    
    assign timer_done = (count >= period-1) ? 1'b1 : 1'b0;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            count <= 8'd0;
        end else begin
            if (processing) begin
                if (timer_done)
                    count <= 8'd0;
                else
                    count <= count + 1'b1;
            end else begin
                count <= 8'd0;
            end
        end
    end
endmodule

//------------------------------------------------
// Phase generator submodule
//------------------------------------------------
module phase_generator (
    input wire clock,
    input wire reset_n,
    input wire phase_shift_en,
    output reg [3:0] phase_outputs
);
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            phase_outputs <= 4'b0001;
        end else if (phase_shift_en) begin
            phase_outputs <= {phase_outputs[2:0], phase_outputs[3]};
        end
    end
endmodule