//SystemVerilog
module StageEnabledShifter #(parameter WIDTH=8) (
    input wire clk,
    input wire [WIDTH-1:0] stage_enable,
    input wire serial_in,
    output reg [WIDTH-1:0] parallel_data_out
);

    // Pipeline stage 1: Capture input and previous parallel data
    reg [WIDTH-1:0] pipeline_stage1_data;
    reg [WIDTH-1:0] pipeline_stage1_en;
    reg pipeline_stage1_serial_in;

    // Pipeline stage 2: Compute shifted data based on enable
    reg [WIDTH-1:0] pipeline_stage2_data;

    integer i;

    // Stage 1: Register input and enables
    always @(posedge clk) begin
        pipeline_stage1_data      <= parallel_data_out;
        pipeline_stage1_en        <= stage_enable;
        pipeline_stage1_serial_in <= serial_in;
    end

    // Stage 2: Combinational logic for conditional shifting
    always @* begin
        // Default: hold previous value
        pipeline_stage2_data = pipeline_stage1_data;
        // Shift logic: for each stage, shift if enabled
        for (i = WIDTH-1; i >= 1; i = i - 1) begin
            if (pipeline_stage1_en[i])
                pipeline_stage2_data[i] = pipeline_stage1_data[i-1];
        end
        if (pipeline_stage1_en[0])
            pipeline_stage2_data[0] = pipeline_stage1_serial_in;
    end

    // Stage 3: Register output
    always @(posedge clk) begin
        parallel_data_out <= pipeline_stage2_data;
    end

endmodule