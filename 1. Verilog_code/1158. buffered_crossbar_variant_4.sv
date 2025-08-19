//SystemVerilog
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
    // Input data slices after selection logic
    wire [WIDTH-1:0] selected_data [0:3];
    
    // Input buffers signals
    reg [WIDTH-1:0] buffers [0:3][0:DEPTH-1];
    reg [2:0] count [0:3];
    reg [1:0] wr_ptr [0:3];
    reg [1:0] rd_ptr [0:3];
    
    // Buffer status signals
    reg [3:0] buf_full_r, buf_empty_r;
    
    // Next state signals (combinational)
    wire [2:0] next_count [0:3];
    wire [1:0] next_wr_ptr [0:3];
    wire [1:0] next_rd_ptr [0:3];
    wire [3:0] next_buf_full;
    wire [3:0] next_buf_empty;
    
    // Buffer write signals
    wire [3:0] buf_write_en;
    
    // ------------------------------------------
    // Combinational logic module instantiation
    // ------------------------------------------
    crossbar_comb_logic #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) comb_logic_inst (
        .in_data(in_data),
        .out_sel(out_sel),
        .write_en(write_en),
        .read_en(read_en),
        .count(count),
        .buf_full_r(buf_full_r),
        .buf_empty_r(buf_empty_r),
        .wr_ptr(wr_ptr),
        .rd_ptr(rd_ptr),
        .buffers(buffers),
        
        .selected_data(selected_data),
        .next_count(next_count),
        .next_wr_ptr(next_wr_ptr),
        .next_rd_ptr(next_rd_ptr),
        .next_buf_full(next_buf_full),
        .next_buf_empty(next_buf_empty),
        .buf_write_en(buf_write_en),
        .out_data(out_data),
        .buf_full(buf_full),
        .buf_empty(buf_empty)
    );
    
    // ------------------------------------------
    // Sequential logic (registers)
    // ------------------------------------------
    integer i, j;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers
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
            // Update all registers from next state signals
            for (i = 0; i < 4; i = i + 1) begin
                // Update pointers and counters
                count[i] <= next_count[i];
                wr_ptr[i] <= next_wr_ptr[i];
                rd_ptr[i] <= next_rd_ptr[i];
                
                // Update status flags
                buf_full_r[i] <= next_buf_full[i];
                buf_empty_r[i] <= next_buf_empty[i];
                
                // Write to buffer when enabled
                if (buf_write_en[i]) begin
                    buffers[i][wr_ptr[i]] <= selected_data[i];
                end
            end
        end
    end
endmodule

// Combinational logic module
module crossbar_comb_logic #(
    parameter WIDTH = 8,
    parameter DEPTH = 2
)(
    // Inputs from top module
    input wire [(WIDTH*4)-1:0] in_data,
    input wire [7:0] out_sel,
    input wire [3:0] write_en,
    input wire [3:0] read_en,
    input wire [2:0] count [0:3],
    input wire [3:0] buf_full_r,
    input wire [3:0] buf_empty_r,
    input wire [1:0] wr_ptr [0:3],
    input wire [1:0] rd_ptr [0:3],
    input wire [WIDTH-1:0] buffers [0:3][0:DEPTH-1],
    
    // Outputs to top module
    output wire [WIDTH-1:0] selected_data [0:3],
    output wire [2:0] next_count [0:3],
    output wire [1:0] next_wr_ptr [0:3],
    output wire [1:0] next_rd_ptr [0:3],
    output wire [3:0] next_buf_full,
    output wire [3:0] next_buf_empty,
    output wire [3:0] buf_write_en,
    output wire [(WIDTH*4)-1:0] out_data,
    output wire [3:0] buf_full,
    output wire [3:0] buf_empty
);
    // Forward buffer status to outputs
    assign buf_full = buf_full_r;
    assign buf_empty = buf_empty_r;
    
    // Data selection logic - pure combinational
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : gen_selectors
            // Select incoming data based on crossbar selection
            assign selected_data[g] = in_data[(out_sel[g*2+:2]*WIDTH) +: WIDTH];
            
            // Determine when to write to buffer (write_en AND not full)
            assign buf_write_en[g] = write_en[g] && !buf_full_r[g];
            
            // Next state logic for counters and pointers
            assign next_count[g] = 
                (write_en[g] && !buf_full_r[g] && read_en[g] && !buf_empty_r[g]) ? count[g] :
                (write_en[g] && !buf_full_r[g]) ? count[g] + 1'b1 :
                (read_en[g] && !buf_empty_r[g]) ? count[g] - 1'b1 : 
                count[g];
                
            assign next_wr_ptr[g] = 
                (write_en[g] && !buf_full_r[g]) ? wr_ptr[g] + 1'b1 : 
                wr_ptr[g];
                
            assign next_rd_ptr[g] = 
                (read_en[g] && !buf_empty_r[g]) ? rd_ptr[g] + 1'b1 : 
                rd_ptr[g];
                
            // Status flag calculations for next cycle
            assign next_buf_full[g] = (next_count[g] == DEPTH);
            assign next_buf_empty[g] = (next_count[g] == 0);
            
            // Output data connections - directly from buffer
            assign out_data[(g*WIDTH) +: WIDTH] = buffers[g][rd_ptr[g]];
        end
    endgenerate
endmodule