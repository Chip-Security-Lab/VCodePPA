//SystemVerilog
///////////////////////////////////////////////////////////
// Module: fixed_prio_arbiter_top
// Description: Top level arbitration module with parameterized width
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////
module fixed_prio_arbiter_top #(
    parameter WIDTH = 4
) (
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] req_i,
    output wire [WIDTH-1:0] grant_o
);
    // Internal signals
    wire [WIDTH-1:0] priority_vector;
    wire req_valid;
    
    // Instantiate priority encoder to determine highest priority request
    priority_encoder #(
        .WIDTH(WIDTH)
    ) u_priority_encoder (
        .req_i(req_i),
        .priority_vector_o(priority_vector),
        .req_valid_o(req_valid)
    );
    
    // Instantiate grant generator to register the grant output
    grant_generator #(
        .WIDTH(WIDTH)
    ) u_grant_generator (
        .clk(clk),
        .rst_n(rst_n),
        .priority_vector_i(priority_vector),
        .req_valid_i(req_valid),
        .grant_o(grant_o)
    );
    
endmodule

///////////////////////////////////////////////////////////
// Module: priority_encoder
// Description: Determines the highest priority request
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////
module priority_encoder #(
    parameter WIDTH = 4
) (
    input wire [WIDTH-1:0] req_i,
    output wire [WIDTH-1:0] priority_vector_o,
    output wire req_valid_o
);
    // Internal signals
    reg [WIDTH-1:0] priority_vector;
    
    // Request valid detection - separate always block
    assign req_valid_o = |req_i;  
    
    // Priority determination - separate logic for each priority level
    wire [WIDTH-1:0] priority_levels [WIDTH-1:0];
    
    // Generate priority vectors for each level
    generate
        genvar i;
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_priority
            assign priority_levels[i] = (req_i[i]) ? 
                                       (1'b1 << i) : 
                                       {WIDTH{1'b0}};
        end
    endgenerate
    
    // Priority resolution
    wire [WIDTH-1:0] resolved_priority;
    
    // Function to resolve priority (could be implemented differently for different PPA targets)
    assign resolved_priority = priority_levels[0] |
                              (priority_levels[0] == {WIDTH{1'b0}} ? priority_levels[1] : {WIDTH{1'b0}}) |
                              (priority_levels[0] == {WIDTH{1'b0}} && priority_levels[1] == {WIDTH{1'b0}} ? priority_levels[2] : {WIDTH{1'b0}}) |
                              (priority_levels[0] == {WIDTH{1'b0}} && priority_levels[1] == {WIDTH{1'b0}} && priority_levels[2] == {WIDTH{1'b0}} ? priority_levels[3] : {WIDTH{1'b0}});
    
    // Final priority vector assignment
    assign priority_vector_o = resolved_priority;
    
endmodule

///////////////////////////////////////////////////////////
// Module: grant_generator
// Description: Registers the granted request based on priority
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////
module grant_generator #(
    parameter WIDTH = 4
) (
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] priority_vector_i,
    input wire req_valid_i,
    output reg [WIDTH-1:0] grant_o
);
    // Internal signals
    reg [WIDTH-1:0] next_grant;
    
    // Reset handling - separate always block
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
        end else begin
            grant_o <= next_grant;
        end
    end
    
    // Next grant determination - separate always block
    always @(*) begin
        next_grant = req_valid_i ? priority_vector_i : {WIDTH{1'b0}};
    end
    
endmodule