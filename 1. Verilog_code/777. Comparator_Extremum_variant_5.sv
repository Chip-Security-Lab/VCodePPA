//SystemVerilog
module Comparator_Extremum #(
    parameter WIDTH = 8,
    parameter NUM_INPUTS = 4
)(
    input  [NUM_INPUTS-1:0][WIDTH-1:0] data_array,
    output [WIDTH-1:0]                 max_val,
    output [$clog2(NUM_INPUTS)-1:0]    max_idx,
    output [WIDTH-1:0]                 min_val,
    output [$clog2(NUM_INPUTS)-1:0]    min_idx 
);
    MaxFinder #(
        .WIDTH(WIDTH),
        .NUM_INPUTS(NUM_INPUTS)
    ) max_finder_inst (
        .data_array(data_array),
        .max_val(max_val),
        .max_idx(max_idx)
    );
    
    MinFinder #(
        .WIDTH(WIDTH),
        .NUM_INPUTS(NUM_INPUTS)
    ) min_finder_inst (
        .data_array(data_array),
        .min_val(min_val),
        .min_idx(min_idx)
    );
endmodule

module MaxFinder #(
    parameter WIDTH = 8,
    parameter NUM_INPUTS = 4
)(
    input  [NUM_INPUTS-1:0][WIDTH-1:0] data_array,
    output reg [WIDTH-1:0]             max_val,
    output reg [$clog2(NUM_INPUTS)-1:0] max_idx
);
    reg [WIDTH-1:0] max_candidates[(NUM_INPUTS+1)/2-1:0];
    reg [$clog2(NUM_INPUTS)-1:0] max_indices[(NUM_INPUTS+1)/2-1:0];
    
    integer i;
    
    always @(*) begin
        i = 0;
        while (i < NUM_INPUTS) begin
            if (i+1 < NUM_INPUTS) begin
                if (data_array[i] > data_array[i+1]) begin
                    max_candidates[i/2] = data_array[i];
                    max_indices[i/2] = i;
                end else begin
                    max_candidates[i/2] = data_array[i+1];
                    max_indices[i/2] = i+1;
                end
            end else begin
                max_candidates[i/2] = data_array[i];
                max_indices[i/2] = i;
            end
            i = i + 2;
        end
        
        max_val = max_candidates[0];
        max_idx = max_indices[0];
        
        i = 1;
        while (i < (NUM_INPUTS+1)/2) begin
            if (max_candidates[i] > max_val) begin
                max_val = max_candidates[i];
                max_idx = max_indices[i];
            end
            i = i + 1;
        end
    end
endmodule

module MinFinder #(
    parameter WIDTH = 8,
    parameter NUM_INPUTS = 4
)(
    input  [NUM_INPUTS-1:0][WIDTH-1:0] data_array,
    output reg [WIDTH-1:0]             min_val,
    output reg [$clog2(NUM_INPUTS)-1:0] min_idx
);
    reg [WIDTH-1:0] min_candidates[(NUM_INPUTS+1)/2-1:0];
    reg [$clog2(NUM_INPUTS)-1:0] min_indices[(NUM_INPUTS+1)/2-1:0];
    
    integer i;
    
    always @(*) begin
        i = 0;
        while (i < NUM_INPUTS) begin
            if (i+1 < NUM_INPUTS) begin
                if (data_array[i] < data_array[i+1]) begin
                    min_candidates[i/2] = data_array[i];
                    min_indices[i/2] = i;
                end else begin
                    min_candidates[i/2] = data_array[i+1];
                    min_indices[i/2] = i+1;
                end
            end else begin
                min_candidates[i/2] = data_array[i];
                min_indices[i/2] = i;
            end
            i = i + 2;
        end
        
        min_val = min_candidates[0];
        min_idx = min_indices[0];
        
        i = 1;
        while (i < (NUM_INPUTS+1)/2) begin
            if (min_candidates[i] < min_val) begin
                min_val = min_candidates[i];
                min_idx = min_indices[i];
            end
            i = i + 1;
        end
    end
endmodule