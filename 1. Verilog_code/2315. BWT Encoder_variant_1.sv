//SystemVerilog
// Top-level module
module bwt_encoder #(parameter WIDTH = 8, LENGTH = 4)(
    input                           clk,
    input                           reset,
    input                           enable,
    input  [WIDTH-1:0]              data_in,
    input                           in_valid,
    output [WIDTH-1:0]              data_out,
    output                          out_valid,
    output [$clog2(LENGTH)-1:0]     index
);
    // Internal connections
    wire                        buffer_full;
    wire [WIDTH-1:0]            pipeline_data;
    wire [$clog2(LENGTH)-1:0]   pipeline_index;
    wire                        pipeline_valid;
    wire [WIDTH-1:0]            buffer_data [0:LENGTH-1];

    // Buffer Management Module
    buffer_manager #(
        .WIDTH(WIDTH),
        .LENGTH(LENGTH)
    ) buffer_mgr_inst (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .data_in(data_in),
        .in_valid(in_valid),
        .buffer_data(buffer_data),
        .buffer_full(buffer_full)
    );

    // BWT Computation Module
    bwt_compute #(
        .WIDTH(WIDTH),
        .LENGTH(LENGTH)
    ) bwt_comp_inst (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .buffer_full(buffer_full),
        .buffer_data(buffer_data),
        .pipeline_data(pipeline_data),
        .pipeline_index(pipeline_index),
        .pipeline_valid(pipeline_valid)
    );

    // Output Stage Module
    output_stage #(
        .WIDTH(WIDTH),
        .LENGTH(LENGTH)
    ) out_stage_inst (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .pipeline_data(pipeline_data),
        .pipeline_index(pipeline_index),
        .pipeline_valid(pipeline_valid),
        .data_out(data_out),
        .index(index),
        .out_valid(out_valid)
    );
endmodule

// Buffer management module - handles data input and buffer filling
module buffer_manager #(parameter WIDTH = 8, LENGTH = 4)(
    input                       clk,
    input                       reset,
    input                       enable,
    input  [WIDTH-1:0]          data_in,
    input                       in_valid,
    output [WIDTH-1:0]          buffer_data [0:LENGTH-1],
    output reg                  buffer_full
);
    // Buffer storage
    reg [WIDTH-1:0] buffer [0:LENGTH-1];
    reg [$clog2(LENGTH)-1:0] buf_ptr;
    
    // Assign buffer contents to output
    genvar i;
    generate
        for (i = 0; i < LENGTH; i = i + 1) begin : BUFFER_ASSIGN
            assign buffer_data[i] = buffer[i];
        end
    endgenerate
    
    // Buffer filling logic
    always @(posedge clk) begin
        if (reset) begin
            buf_ptr <= 0;
            buffer_full <= 0;
            
            // Clear buffer on reset
            for (int j = 0; j < LENGTH; j = j + 1) begin
                buffer[j] <= 0;
            end
        end else if (enable && in_valid) begin
            // Fill buffer
            buffer[buf_ptr] <= data_in;
            
            if (buf_ptr == LENGTH-1) begin
                // Buffer full, set flag for next stage
                buffer_full <= 1;
                buf_ptr <= 0;
            end else begin
                buf_ptr <= buf_ptr + 1;
                buffer_full <= 0;
            end
        end else begin
            buffer_full <= 0;
        end
    end
endmodule

// BWT computation module - performs Burrows-Wheeler Transform
module bwt_compute #(parameter WIDTH = 8, LENGTH = 4)(
    input                           clk,
    input                           reset,
    input                           enable,
    input                           buffer_full,
    input  [WIDTH-1:0]              buffer_data [0:LENGTH-1],
    output reg [WIDTH-1:0]          pipeline_data,
    output reg [$clog2(LENGTH)-1:0] pipeline_index,
    output reg                      pipeline_valid
);
    // BWT computation logic
    always @(posedge clk) begin
        if (reset) begin
            pipeline_valid <= 0;
            pipeline_data <= 0;
            pipeline_index <= 0;
        end else if (enable) begin
            if (buffer_full) begin
                // Compute BWT (simplified for this example)
                // In a full implementation, this would sort the rotations
                // and select the last column
                pipeline_data <= buffer_data[0];
                pipeline_index <= 0;
                pipeline_valid <= 1;
            end else begin
                pipeline_valid <= 0;
            end
        end else begin
            pipeline_valid <= 0;
        end
    end
endmodule

// Output stage module - handles final output
module output_stage #(parameter WIDTH = 8, LENGTH = 4)(
    input                           clk,
    input                           reset,
    input                           enable,
    input  [WIDTH-1:0]              pipeline_data,
    input  [$clog2(LENGTH)-1:0]     pipeline_index,
    input                           pipeline_valid,
    output reg [WIDTH-1:0]          data_out,
    output reg [$clog2(LENGTH)-1:0] index,
    output reg                      out_valid
);
    // Output register control
    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
            index <= 0;
            out_valid <= 0;
        end else if (enable) begin
            data_out <= pipeline_data;
            index <= pipeline_index;
            out_valid <= pipeline_valid;
        end else begin
            out_valid <= 0;
        end
    end
endmodule