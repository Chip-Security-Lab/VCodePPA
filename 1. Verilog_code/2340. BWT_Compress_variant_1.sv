//SystemVerilog
// Top-level module
module BWT_Compress #(
    parameter BLK = 8
) (
    input wire clk,
    input wire rst_n,  // Added reset signal
    input wire valid_in,  // Input valid signal
    input wire [BLK*8-1:0] data_in,
    output wire valid_out,  // Output valid signal
    output wire [BLK*8-1:0] data_out,
    output wire ready_in  // Ready to accept new data
);
    // Pipeline control signals
    wire valid_stage1, valid_stage2;
    wire ready_stage1, ready_stage2, ready_stage3;

    // Internal signals for connecting submodules
    wire [BLK*8-1:0] buffer_data_stage1;
    wire [BLK*8-1:0] sorted_data_stage2;
    
    assign ready_in = ready_stage1;
    
    // Input data extraction module
    DataExtractor #(
        .BLK(BLK)
    ) data_extractor_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .ready_in(ready_stage1),
        .data_in(data_in),
        .valid_out(valid_stage1),
        .ready_out(ready_stage2),
        .data_out(buffer_data_stage1)
    );
    
    // Data sorting module
    DataSorter #(
        .BLK(BLK)
    ) data_sorter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_stage1),
        .ready_in(ready_stage2),
        .data_in(buffer_data_stage1),
        .valid_out(valid_stage2),
        .ready_out(ready_stage3),
        .data_out(sorted_data_stage2)
    );
    
    // Output data assembly module
    DataAssembler #(
        .BLK(BLK)
    ) data_assembler_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_stage2),
        .ready_in(ready_stage3),
        .data_in(sorted_data_stage2),
        .valid_out(valid_out),
        .data_out(data_out)
    );
    
endmodule

// Data extraction module
module DataExtractor #(
    parameter BLK = 8
) (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    output wire ready_in,
    input wire [BLK*8-1:0] data_in,
    output reg valid_out,
    input wire ready_out,
    output reg [BLK*8-1:0] data_out
);
    // Always ready to accept data
    assign ready_in = ready_out || !valid_out;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            data_out <= {(BLK*8){1'b0}};
        end else if (ready_out || !valid_out) begin
            if (valid_in) begin
                // Extract data directly - no transformation needed at this stage
                data_out <= data_in;
                valid_out <= 1'b1;
            end else if (ready_out) begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule

// Data sorting module
module DataSorter #(
    parameter BLK = 8
) (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    output wire ready_in,
    input wire [BLK*8-1:0] data_in,
    output reg valid_out,
    input wire ready_out,
    output reg [BLK*8-1:0] data_out
);
    // Pipeline stages for sorting
    reg [2:0] pipeline_stage;
    reg [7:0] buffer [0:BLK-1];
    reg [7:0] sorted [0:BLK-1];
    reg [7:0] temp;
    
    reg valid_pipe [0:2];
    reg [BLK*8-1:0] data_pipe [0:1];
    
    integer i, j, p;
    
    // State parameters
    localparam IDLE = 3'd0;
    localparam LOAD = 3'd1;
    localparam SORT_OUTER_LOOP = 3'd2;
    localparam SORT_INNER_LOOP = 3'd3;
    localparam PACK_DATA = 3'd4;
    localparam OUTPUT_DATA = 3'd5;
    
    // Sorting pipeline control variables
    reg [3:0] outer_idx, inner_idx;
    reg swapped;
    
    // Flowcontrol
    assign ready_in = (pipeline_stage == IDLE) && (ready_out || !valid_out);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_stage <= IDLE;
            valid_out <= 1'b0;
            data_out <= {(BLK*8){1'b0}};
            outer_idx <= 0;
            inner_idx <= 0;
            swapped <= 0;
            
            for (p = 0; p < 3; p = p+1) begin
                valid_pipe[p] <= 1'b0;
            end
            
            for (p = 0; p < 2; p = p+1) begin
                data_pipe[p] <= {(BLK*8){1'b0}};
            end
        end else begin
            case (pipeline_stage)
                IDLE: begin
                    if (valid_in && ready_in) begin
                        // Extract data to buffer
                        for (i = 0; i < BLK; i = i+1)
                            buffer[i] <= data_in[i*8 +: 8];
                        
                        // Copy to sorting array
                        for (i = 0; i < BLK; i = i+1)
                            sorted[i] <= data_in[i*8 +: 8];
                            
                        pipeline_stage <= SORT_OUTER_LOOP;
                        outer_idx <= 0;
                    end
                end
                
                SORT_OUTER_LOOP: begin
                    if (outer_idx < BLK-1) begin
                        inner_idx <= 0;
                        swapped <= 0;
                        pipeline_stage <= SORT_INNER_LOOP;
                    end else begin
                        pipeline_stage <= PACK_DATA;
                    end
                end
                
                SORT_INNER_LOOP: begin
                    if (inner_idx < BLK-1-outer_idx) begin
                        if (sorted[inner_idx] > sorted[inner_idx+1]) begin
                            temp <= sorted[inner_idx];
                            sorted[inner_idx] <= sorted[inner_idx+1];
                            sorted[inner_idx+1] <= temp;
                            swapped <= 1;
                        end
                        inner_idx <= inner_idx + 1;
                    end else begin
                        outer_idx <= outer_idx + 1;
                        pipeline_stage <= SORT_OUTER_LOOP;
                        // Early exit optimization if no swaps occurred
                        if (!swapped && outer_idx > 0) begin
                            pipeline_stage <= PACK_DATA;
                        end
                    end
                end
                
                PACK_DATA: begin
                    // Pack sorted data to output
                    for (i = 0; i < BLK; i = i+1)
                        data_out[i*8 +: 8] <= sorted[i];
                    
                    valid_out <= 1'b1;
                    pipeline_stage <= OUTPUT_DATA;
                end
                
                OUTPUT_DATA: begin
                    if (ready_out) begin
                        valid_out <= 1'b0;
                        pipeline_stage <= IDLE;
                    end
                end
                
                default: pipeline_stage <= IDLE;
            endcase
        end
    end
endmodule

// Data assembly module for BWT output format
module DataAssembler #(
    parameter BLK = 8
) (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    output wire ready_in,
    input wire [BLK*8-1:0] data_in,
    output reg valid_out,
    output reg [BLK*8-1:0] data_out
);
    reg [7:0] buffer [0:BLK-1];
    reg [BLK*8-1:0] data_stage1;
    reg valid_stage1;
    
    integer i;
    
    // Always ready to accept new data when not processing
    assign ready_in = !valid_stage1;
    
    // First pipeline stage: Load data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            for (i = 0; i < BLK; i = i+1)
                buffer[i] <= 8'h0;
        end else begin
            if (valid_in && ready_in) begin
                // Extract data to buffer
                for (i = 0; i < BLK; i = i+1)
                    buffer[i] <= data_in[i*8 +: 8];
                valid_stage1 <= 1'b1;
            end else if (valid_stage1 && !valid_out) begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Second pipeline stage: Assemble BWT format output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            data_out <= {(BLK*8){1'b0}};
        end else begin
            if (valid_stage1 && !valid_out) begin
                // Assemble output in BWT format:
                // Last byte first, then the remaining bytes
                data_out[7:0] <= buffer[BLK-1];
                for (i = 1; i < BLK; i = i+1)
                    data_out[i*8 +: 8] <= buffer[i-1];
                valid_out <= 1'b1;
            end else if (!valid_stage1 && valid_out) begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule