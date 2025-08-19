//SystemVerilog
module burst_arbiter #(
    parameter WIDTH = 4,
    parameter BURST = 4
) (
    input  logic clk,    
    input  logic rst_n,
    input  logic [WIDTH-1:0] req_i,
    output logic [WIDTH-1:0] grant_o
);

    logic [3:0] counter;
    logic [WIDTH-1:0] current;
    logic [3:0] counter_next;
    
    // Instantiate subtractor module
    logic [3:0] counter_minus_one;
    conditional_subtractor u_subtractor (
        .counter(counter),
        .counter_minus_one(counter_minus_one)
    );
    
    // Instantiate counter controller module
    counter_controller #(
        .BURST(BURST)
    ) u_counter_controller (
        .counter(counter),
        .counter_minus_one(counter_minus_one),
        .req_valid(req_i != 0),
        .counter_next(counter_next)
    );
    
    // Instantiate priority encoder module
    priority_encoder #(
        .WIDTH(WIDTH)
    ) u_priority_encoder (
        .req_i(req_i),
        .encoded_o(current),
        .counter(counter),
        .clk(clk),
        .rst_n(rst_n)
    );
    
    // Main sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
            grant_o <= '0;
        end else begin
            counter <= counter_next;
            grant_o <= current;
        end
    end

endmodule

// Conditional sum subtractor module
module conditional_subtractor (
    input  logic [3:0] counter,
    output logic [3:0] counter_minus_one
);
    
    logic [3:0] borrow;
    
    // Conditional sum subtractor implementation - subtracts 1 from counter
    assign borrow[0] = 1'b1; // Initial borrow-in for subtraction
    assign counter_minus_one[0] = counter[0] ^ borrow[0];
    assign borrow[1] = ~counter[0] & borrow[0];
    assign counter_minus_one[1] = counter[1] ^ borrow[1];
    assign borrow[2] = ~counter[1] & borrow[1];
    assign counter_minus_one[2] = counter[2] ^ borrow[2];
    assign borrow[3] = ~counter[2] & borrow[2];
    assign counter_minus_one[3] = counter[3] ^ borrow[3];

endmodule

// Counter controller module
module counter_controller #(
    parameter BURST = 4
) (
    input  logic [3:0] counter,
    input  logic [3:0] counter_minus_one,
    input  logic req_valid,
    output logic [3:0] counter_next
);

    // Determine next counter value based on current state
    always_comb begin
        if (counter == 0) begin
            counter_next = req_valid ? BURST-1 : '0;
        end else begin
            counter_next = counter_minus_one;
        end
    end

endmodule

// Priority encoder module
module priority_encoder #(
    parameter WIDTH = 4
) (
    input  logic clk,
    input  logic rst_n,
    input  logic [WIDTH-1:0] req_i,
    input  logic [3:0] counter,
    output logic [WIDTH-1:0] encoded_o
);

    // Priority encoder implementation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_o <= '0;
        end else if (counter == 0) begin
            encoded_o <= req_i & (~req_i + 1); // Priority encoder - isolates least significant set bit
        end
    end

endmodule