//SystemVerilog
module d_ff_async_preset_pipelined (
    input wire clk,
    input wire rst_n,
    input wire preset_n,
    input wire d,
    input wire valid_in,
    output wire valid_out,
    output reg q
);
    // Pipeline stage registers
    reg d_stage1, d_stage2;
    reg valid_stage1, valid_stage2;
    
    // Asynchronous reset and preset logic remains the same
    always @(negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;
            d_stage1 <= 1'b0;
            d_stage2 <= 1'b0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
    end
    
    always @(negedge preset_n) begin
        if (rst_n && !preset_n) begin
            q <= 1'b1;
            // Pipeline stages are not affected by preset
        end
    end
    
    // Pipeline stage 1: Input registration
    always @(posedge clk) begin
        if (rst_n && preset_n) begin
            d_stage1 <= d;
            valid_stage1 <= valid_in;
        end
    end
    
    // Pipeline stage 2: Processing stage
    always @(posedge clk) begin
        if (rst_n && preset_n) begin
            d_stage2 <= d_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Output registration
    always @(posedge clk) begin
        if (rst_n && preset_n) begin
            if (valid_stage2)
                q <= d_stage2;
            // Only update output when valid signal is high
        end
    end
    
    // Valid output signal
    assign valid_out = valid_stage2;
    
endmodule