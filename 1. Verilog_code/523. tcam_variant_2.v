module tcam #(parameter WIDTH=32, DEPTH=64)(
    input clk,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] write_mask,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] mask_in,
    output [DEPTH-1:0] hit_lines
);
    reg [WIDTH-1:0] tcam_data [0:DEPTH-1];
    reg [WIDTH-1:0] tcam_mask [0:DEPTH-1];
    
    always @(posedge clk) begin
        if (write_en) begin
            tcam_data[write_addr] <= write_data;
            tcam_mask[write_addr] <= write_mask;
        end
    end
    
    genvar i;
    generate
        for(i=0; i<DEPTH; i=i+1) begin : gen_match
            wire [WIDTH-1:0] masked_data_in = data_in & tcam_mask[i];
            wire [WIDTH-1:0] masked_tcam_data = tcam_data[i] & tcam_mask[i];
            wire [WIDTH:0] borrow;
            wire [WIDTH-1:0] diff;
            
            assign borrow[0] = 1'b0;
            
            genvar j;
            for(j=0; j<WIDTH; j=j+1) begin : gen_sub
                wire [1:0] sub_result = {1'b0, masked_data_in[j]} - {1'b0, masked_tcam_data[j]} - {1'b0, borrow[j]};
                assign diff[j] = sub_result[0];
                assign borrow[j+1] = sub_result[1];
            end
            
            assign hit_lines[i] = ~(|diff);
        end
    endgenerate
endmodule