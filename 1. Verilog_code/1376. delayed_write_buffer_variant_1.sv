//SystemVerilog
module delayed_write_buffer (
    input  wire        clk,
    input  wire [15:0] data_in,
    input  wire        trigger,
    output reg  [15:0] data_out
);
    // Stage 1: Input registration
    reg [15:0] stage1_data;
    reg        stage1_trigger;
    
    // Stage 2: Control signal generation
    reg        stage2_write_pending;
    reg [15:0] stage2_data;
    
    // Stage 1: Register input signals
    always @(posedge clk) begin
        stage1_data <= data_in;
        stage1_trigger <= trigger;
    end
    
    // Stage 2: Control logic generation
    always @(posedge clk) begin
        if (stage1_trigger) begin
            stage2_write_pending <= 1'b1;
            stage2_data <= stage1_data;
        end else if (stage2_write_pending) begin
            stage2_write_pending <= 1'b0;
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clk) begin
        if (stage2_write_pending) begin
            data_out <= stage2_data;
        end
    end
endmodule