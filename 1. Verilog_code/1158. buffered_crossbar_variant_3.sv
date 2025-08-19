//SystemVerilog
//IEEE 1364-2005 Verilog standard
module buffered_crossbar #(
    parameter WIDTH = 8,
    parameter DEPTH = 2  // Buffer depth as power of 2
)(
    input wire clk, rst_n,
    input wire [(WIDTH*4)-1:0] in_data, // Flattened 4xWIDTH array
    input wire [7:0] out_sel,     // Flattened 4x2 array 
    input wire [3:0] write_en,    // Write enable for input buffers
    input wire [3:0] read_en,     // Read enable for output buffers
    output wire [(WIDTH*4)-1:0] out_data, // Flattened 4xWIDTH array
    output wire [3:0] buf_full, buf_empty
);
    // Combined pipeline stages (reduced from 3 to 2 stages)
    // Stage 1: Input Processing and Crossbar Routing
    reg [(WIDTH*4)-1:0] in_data_stage1;
    reg [7:0] out_sel_stage1;
    reg [3:0] write_en_stage1, read_en_stage1;
    reg valid_stage1;
    reg [WIDTH-1:0] write_data_stage1 [0:3]; // Moved from stage2 to stage1
    
    // Buffer management registers
    reg [WIDTH-1:0] buffers [0:3][0:DEPTH-1];
    reg [2:0] count [0:3];
    reg wr_ptr [0:3];
    reg rd_ptr [0:3];
    
    // Output registers (previously stage3)
    reg [WIDTH-1:0] read_data_out [0:3];
    
    // Buffer status signals
    reg [3:0] buf_full_r, buf_empty_r;
    
    integer i, j;

    // Stage 1: Register inputs, calculate write data, and prepare crossbar routing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_data_stage1 <= 0;
            out_sel_stage1 <= 0;
            write_en_stage1 <= 0;
            read_en_stage1 <= 0;
            valid_stage1 <= 0;
            for (i = 0; i < 4; i = i + 1) begin
                write_data_stage1[i] <= 0;
            end
        end else begin
            in_data_stage1 <= in_data;
            out_sel_stage1 <= out_sel;
            write_en_stage1 <= write_en;
            read_en_stage1 <= read_en;
            valid_stage1 <= 1'b1;
            
            // Data routing calculation moved to stage 1 (was in stage 2)
            for (i = 0; i < 4; i = i + 1) begin
                // Extract data slice based on selector
                write_data_stage1[i] <= in_data[(out_sel[i*2+:2]*WIDTH) +: WIDTH];
            end
        end
    end
    
    // Combined buffer management - handles both write and read operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 4; i = i + 1) begin
                count[i] <= 0;
                wr_ptr[i] <= 0;
                rd_ptr[i] <= 0;
                buf_full_r[i] <= 0;
                buf_empty_r[i] <= 1; // Empty initially
                read_data_out[i] <= 0;
                for (j = 0; j < DEPTH; j = j + 1) begin
                    buffers[i][j] <= 0;
                end
            end
        end else begin
            for (i = 0; i < 4; i = i + 1) begin
                // Update full/empty flags
                buf_full_r[i] <= (count[i] == DEPTH);
                buf_empty_r[i] <= (count[i] == 0);
                
                // Write operation (directly from stage 1)
                if (valid_stage1 && write_en_stage1[i] && !buf_full_r[i]) begin
                    buffers[i][wr_ptr[i]] <= write_data_stage1[i];
                    wr_ptr[i] <= wr_ptr[i] + 1;
                    if (!read_en_stage1[i] || buf_empty_r[i]) begin
                        count[i] <= count[i] + 1;
                    end
                end
                
                // Read operation (directly to output)
                if (valid_stage1 && read_en_stage1[i] && !buf_empty_r[i]) begin
                    read_data_out[i] <= buffers[i][rd_ptr[i]];
                    rd_ptr[i] <= rd_ptr[i] + 1;
                    if (!write_en_stage1[i] || buf_full_r[i]) begin
                        count[i] <= count[i] - 1;
                    end
                end
                
                // Handle simultaneous read and write correctly
                if (valid_stage1 && write_en_stage1[i] && read_en_stage1[i] && 
                    !buf_full_r[i] && !buf_empty_r[i]) begin
                    // Count remains the same when both read and write happen
                    count[i] <= count[i];
                end
            end
        end
    end
    
    // Output assignments using generate for cleaner code
    genvar g;
    generate 
        for (g = 0; g < 4; g = g + 1) begin : gen_outputs
            assign buf_full[g] = buf_full_r[g];
            assign buf_empty[g] = buf_empty_r[g];
            assign out_data[(g*WIDTH) +: WIDTH] = read_data_out[g];
        end
    endgenerate
endmodule