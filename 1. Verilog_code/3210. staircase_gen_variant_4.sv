//SystemVerilog
module staircase_gen(
    input clock,
    input reset_n,
    input [2:0] step_size,
    input [4:0] num_steps,
    input valid,
    output ready,
    output reg [7:0] staircase
);
    reg [4:0] step_counter;
    reg busy;
    
    // Buffer registers for high fanout signals
    reg [2:0] step_size_buf;
    reg [4:0] num_steps_buf;
    reg valid_buf;
    reg busy_buf;
    
    // Ready signal generation - when module is not busy
    assign ready = !busy;
    
    // First stage: Buffer input signals
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            step_size_buf <= 3'h0;
            num_steps_buf <= 5'h0;
            valid_buf <= 1'b0;
            busy_buf <= 1'b0;
        end else begin
            step_size_buf <= step_size;
            num_steps_buf <= num_steps;
            valid_buf <= valid;
            busy_buf <= busy;
        end
    end
    
    // Main logic with balanced fanout
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            staircase <= 8'h00;
            step_counter <= 5'h00;
            busy <= 1'b0;
        end else begin
            if (valid_buf && !busy_buf) begin
                // New valid data received and ready to process
                busy <= 1'b1;
                staircase <= {5'b0, step_size_buf}; // First step directly set
                step_counter <= 5'h01;              // First step completed
            end else if (busy_buf) begin
                if (step_counter >= num_steps_buf) begin
                    // All steps completed
                    staircase <= 8'h00;
                    step_counter <= 5'h00;
                    busy <= 1'b0;  // Processing complete, ready for new data
                end else begin
                    // Continue generating next step
                    staircase <= staircase + {5'b0, step_size_buf};
                    step_counter <= step_counter + 5'h01;
                end
            end
        end
    end
endmodule