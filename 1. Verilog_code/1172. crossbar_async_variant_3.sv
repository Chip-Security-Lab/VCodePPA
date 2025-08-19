//SystemVerilog
module crossbar_mult_async #(parameter WIDTH=16, INPUTS=3, OUTPUTS=3) (
    input [(WIDTH*INPUTS)-1:0] in_data,
    input [(OUTPUTS*INPUTS)-1:0] req,
    input [7:0] mult_in_a,
    input [7:0] mult_in_b,
    output [15:0] mult_result,
    output reg [(WIDTH*OUTPUTS)-1:0] out_data
);

// Baugh-Wooley 8x8 bit multiplier implementation
wire [7:0] a, b;
assign a = mult_in_a;
assign b = mult_in_b;

// Partial product generation
wire [7:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;
wire [15:0] ext_pp0, ext_pp1, ext_pp2, ext_pp3, ext_pp4, ext_pp5, ext_pp6, ext_pp7;

// Generate partial products with Baugh-Wooley sign handling
assign pp0 = a & {8{b[0]}};
assign pp1 = a & {8{b[1]}};
assign pp2 = a & {8{b[2]}};
assign pp3 = a & {8{b[3]}};
assign pp4 = a & {8{b[4]}};
assign pp5 = a & {8{b[5]}};
assign pp6 = a & {8{b[6]}};
assign pp7 = (~a) & {8{b[7]}}; // Invert for negative weight in MSB

// Sign extension and shifting for partial products
assign ext_pp0 = {{8{1'b0}}, pp0};
assign ext_pp1 = {{7{1'b0}}, pp1, {1{1'b0}}};
assign ext_pp2 = {{6{1'b0}}, pp2, {2{1'b0}}};
assign ext_pp3 = {{5{1'b0}}, pp3, {3{1'b0}}};
assign ext_pp4 = {{4{1'b0}}, pp4, {4{1'b0}}};
assign ext_pp5 = {{3{1'b0}}, pp5, {5{1'b0}}};
assign ext_pp6 = {{2{1'b0}}, pp6, {6{1'b0}}};
assign ext_pp7 = {{1{1'b0}}, pp7, {7{1'b0}}};

// Correction term for Baugh-Wooley algorithm
wire [15:0] correction;
assign correction = 16'h8000; // 2^15 for 8x8 multiplication

// Final summation with carry-save adders and a final carry-propagate adder
wire [15:0] sum;
assign sum = ext_pp0 + ext_pp1 + ext_pp2 + ext_pp3 + 
             ext_pp4 + ext_pp5 + ext_pp6 + ext_pp7 + correction;

// Output multiplication result
assign mult_result = sum;

// Original crossbar logic
genvar o, i;
generate 
    for(o=0; o<OUTPUTS; o=o+1) begin : gen_out
        wire [INPUTS-1:0] req_vec;
        wire any_req;
        reg [WIDTH-1:0] out_temp;
        
        // Extract request bits for this output
        for(i=0; i<INPUTS; i=i+1) begin : gen_req
            assign req_vec[i] = req[i*OUTPUTS + o];
        end
        
        assign any_req = |req_vec;
        
        // Priority encoder implementation using case instead of dynamic loop
        always @(*) begin
            out_temp = {WIDTH{1'b0}};
            casez(req_vec)
                3'b??1: out_temp = in_data[WIDTH-1:0];
                3'b?10: out_temp = in_data[2*WIDTH-1:WIDTH];
                3'b100: out_temp = in_data[3*WIDTH-1:2*WIDTH];
                default: out_temp = {WIDTH{1'b0}};
            endcase
        end
        
        // Output data selection
        always @(*) begin
            if (any_req) begin
                out_data[(o+1)*WIDTH-1:o*WIDTH] = out_temp;
            end else begin
                out_data[(o+1)*WIDTH-1:o*WIDTH] = {WIDTH{1'b0}};
            end
        end
    end
endgenerate
endmodule