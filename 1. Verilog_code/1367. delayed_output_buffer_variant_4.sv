//SystemVerilog
module delayed_output_buffer (
    input wire clk,
    input wire [7:0] data_in,
    input wire valid_in,     // sender's valid signal
    input wire ready_out,    // receiver's ready signal
    output reg [7:0] data_out,
    output reg valid_out     // output valid signal
);
    // Stage 1: Input capture
    reg [7:0] data_stage1;
    reg valid_stage1;
    wire ready_stage1;       // Ready signal for stage 1
    
    // Stage 2: Buffer stage
    reg [7:0] data_stage2;
    reg valid_stage2;
    wire ready_stage2;       // Ready signal for stage 2
    
    // Stage 3: Output preparation
    reg [7:0] data_stage3;
    reg valid_stage3;
    wire ready_stage3;       // Ready signal for stage 3
    
    // Ready propagation (backpressure) - determine when each stage can accept new data
    assign ready_stage3 = !valid_stage3 || ready_out;
    assign ready_stage2 = !valid_stage2 || ready_stage3;
    assign ready_stage1 = !valid_stage1 || ready_stage2;
    
    // Stage 1: Input capture with valid-ready handshake
    always @(posedge clk) begin
        if (ready_stage1 && valid_in) begin
            data_stage1 <= data_in;
            valid_stage1 <= 1'b1;
        end else if (ready_stage2 && valid_stage1) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Buffer stage with valid-ready handshake
    always @(posedge clk) begin
        if (ready_stage2 && valid_stage1) begin
            data_stage2 <= data_stage1;
            valid_stage2 <= 1'b1;
        end else if (ready_stage3 && valid_stage2) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Stage 3: Output preparation with valid-ready handshake
    always @(posedge clk) begin
        if (ready_stage3 && valid_stage2) begin
            data_stage3 <= data_stage2;
            valid_stage3 <= 1'b1;
        end else if (ready_out && valid_stage3) begin
            valid_stage3 <= 1'b0;
        end
    end
    
    // Output register stage with valid-ready handshake
    always @(posedge clk) begin
        if (ready_out && valid_stage3) begin
            data_out <= data_stage3;
            valid_out <= 1'b1;
        end else if (ready_out && valid_out) begin
            valid_out <= 1'b0;
        end
    end
endmodule