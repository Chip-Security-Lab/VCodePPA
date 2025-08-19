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
    // Input buffers organized as arrays for clearer code
    reg [WIDTH-1:0] buffers [0:3][0:DEPTH-1];
    reg [2:0] count [0:3];
    reg wr_ptr [0:3];
    reg rd_ptr [0:3];
    
    // Buffer status signals
    reg [3:0] buf_full_r, buf_empty_r;
    
    integer i, j;
    
    // Buffer management logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 4; i = i + 1) begin
                count[i] <= 0;
                wr_ptr[i] <= 0;
                rd_ptr[i] <= 0;
                buf_full_r[i] <= 0;
                buf_empty_r[i] <= 1; // Empty initially
                for (j = 0; j < DEPTH; j = j + 1) begin
                    buffers[i][j] <= 0;
                end
            end
        end else begin
            for (i = 0; i < 4; i = i + 1) begin
                // Update full/empty flags
                buf_full_r[i] <= (count[i] == DEPTH);
                buf_empty_r[i] <= (count[i] == 0);
                
                // Write to buffer
                if (write_en[i] && !buf_full_r[i]) begin
                    // Extract correct slice from input data based on selector
                    buffers[i][wr_ptr[i]] <= in_data[(out_sel[i*2+:2]*WIDTH) +: WIDTH];
                    wr_ptr[i] <= wr_ptr[i] + 1;
                    count[i] <= count[i] + 1;
                end
                
                // Read from buffer
                if (read_en[i] && !buf_empty_r[i]) begin
                    rd_ptr[i] <= rd_ptr[i] + 1;
                    count[i] <= count[i] - 1;
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
            assign out_data[(g*WIDTH) +: WIDTH] = buffers[g][rd_ptr[g]];
        end
    endgenerate
endmodule