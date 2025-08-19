module cam_clock_gated #(parameter WIDTH=8, DEPTH=32)(
    input clk,
    input search_en,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] data_in,
    output reg [DEPTH-1:0] match_flags
);
    reg [WIDTH-1:0] entries [0:DEPTH-1];
    reg [WIDTH-1:0] data_in_reg;
    reg search_en_reg;
    reg [DEPTH-1:0] match_flags_pipe;
    
    // Write logic
    always @(posedge clk) begin
        if (write_en)
            entries[write_addr] <= write_data;
    end
    
    // Pipeline stage 1: Register input data and search enable
    always @(posedge clk) begin
        data_in_reg <= data_in;
        search_en_reg <= search_en;
    end
    
    // Pipeline stage 2: Parallel prefix comparison
    genvar i;
    generate
        for(i=0; i<DEPTH; i=i+1) begin: COMPARE_BLOCK
            wire [WIDTH-1:0] diff = entries[i] ^ data_in_reg;
            wire [WIDTH-1:0] carry;
            wire [WIDTH-1:0] prop;
            wire [WIDTH-1:0] gen;
            
            // Generate and propagate signals
            assign gen = ~diff;
            assign prop = diff;
            
            // Parallel prefix network
            wire [WIDTH-1:0] carry_out;
            parallel_prefix_adder #(.WIDTH(WIDTH)) ppa (
                .gen(gen),
                .prop(prop),
                .carry_in(1'b1),
                .carry_out(carry_out)
            );
            
            // Match flag generation
            always @(posedge clk) begin
                if (search_en_reg)
                    match_flags_pipe[i] <= &carry_out;
            end
        end
    endgenerate
    
    // Pipeline stage 3: Output stage
    always @(posedge clk) begin
        match_flags <= match_flags_pipe;
    end
endmodule

module parallel_prefix_adder #(parameter WIDTH=8)(
    input [WIDTH-1:0] gen,
    input [WIDTH-1:0] prop,
    input carry_in,
    output [WIDTH-1:0] carry_out
);
    wire [WIDTH-1:0] g [0:WIDTH-1];
    wire [WIDTH-1:0] p [0:WIDTH-1];
    
    // Initialize first level
    assign g[0] = gen;
    assign p[0] = prop;
    
    // Generate parallel prefix network
    genvar i, j;
    generate
        for(i=1; i<WIDTH; i=i+1) begin: PREFIX_LEVEL
            for(j=0; j<WIDTH; j=j+1) begin: PREFIX_CELL
                if(j >= (1<<(i-1))) begin
                    assign g[i][j] = g[i-1][j] | (p[i-1][j] & g[i-1][j-(1<<(i-1))]);
                    assign p[i][j] = p[i-1][j] & p[i-1][j-(1<<(i-1))];
                end else begin
                    assign g[i][j] = g[i-1][j];
                    assign p[i][j] = p[i-1][j];
                end
            end
        end
    endgenerate
    
    // Final carry computation
    assign carry_out = g[WIDTH-1] | (p[WIDTH-1] & {WIDTH{carry_in}});
endmodule