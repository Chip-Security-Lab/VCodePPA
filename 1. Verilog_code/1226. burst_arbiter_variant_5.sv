//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
// Top module - burst_arbiter
module burst_arbiter #(
    parameter WIDTH = 4,
    parameter BURST = 4
) (
    input  wire               clk,
    input  wire               rst_n,
    input  wire [WIDTH-1:0]   req_i,
    output reg  [WIDTH-1:0]   grant_o
);

    wire [3:0]       counter_next;
    wire [WIDTH-1:0] current_next;
    reg  [3:0]       counter;
    reg  [WIDTH-1:0] current;

    // Instantiate arbiter state logic module
    arbiter_state_logic #(
        .WIDTH(WIDTH),
        .BURST(BURST)
    ) state_logic_inst (
        .counter     (counter),
        .current     (current),
        .req_i       (req_i),
        .counter_next(counter_next),
        .current_next(current_next)
    );

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'b0;
            current <= {WIDTH{1'b0}};
            grant_o <= {WIDTH{1'b0}};
        end else begin
            counter <= counter_next;
            current <= current_next;
            grant_o <= current;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Optimized arbiter state logic module
module arbiter_state_logic #(
    parameter WIDTH = 4,
    parameter BURST = 4
) (
    input  wire [3:0]         counter,
    input  wire [WIDTH-1:0]   current,
    input  wire [WIDTH-1:0]   req_i,
    output reg  [3:0]         counter_next,
    output reg  [WIDTH-1:0]   current_next
);

    // Use a priority encoder approach for improved efficiency
    reg [WIDTH-1:0] next_grant;
    
    // Optimized priority encoding logic with better timing characteristics
    always @(*) begin
        // Default values
        next_grant = {WIDTH{1'b0}};
        
        // Priority encoding with optimized comparison chain
        if (|req_i) begin
            // Parameterized priority encoder
            integer i;
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (req_i[i] && next_grant == {WIDTH{1'b0}}) begin
                    next_grant[i] = 1'b1;
                end
            end
        end
        
        // Optimized counter and grant logic with explicit state handling
        if (counter == 4'b0) begin
            if (|req_i) begin
                counter_next = BURST - 4'b1;
                current_next = next_grant;
            end else begin
                counter_next = 4'b0;
                current_next = current;
            end
        end else begin
            counter_next = counter - 4'b1;
            current_next = current;
        end
    end

endmodule