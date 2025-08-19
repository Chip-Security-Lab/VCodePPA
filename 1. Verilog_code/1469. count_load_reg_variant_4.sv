//SystemVerilog
// Top Level Module
module count_load_reg (
    input wire clk,
    input wire rst,
    input wire [7:0] load_val,
    input wire load_req,
    output reg load_ack,
    input wire count_req,
    output reg count_ack,
    output wire [7:0] count
);
    // Internal signals
    wire [7:0] next_count;
    wire [7:0] current_count;
    wire load_valid;
    wire count_valid;
    
    // Generate valid signals from req-ack handshake
    assign load_valid = load_req && load_ack;
    assign count_valid = count_req && count_ack;
    
    // Acknowledge logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            load_ack <= 1'b0;
            count_ack <= 1'b0;
        end
        else begin
            load_ack <= load_req;
            count_ack <= count_req;
        end
    end
    
    // Instance of control logic
    counter_control u_counter_control (
        .load(load_valid),
        .count_en(count_valid),
        .load_val(load_val),
        .current_count(current_count),
        .next_count(next_count)
    );
    
    // Instance of counter register
    counter_register u_counter_register (
        .clk(clk),
        .rst(rst),
        .next_count(next_count),
        .count(current_count)
    );
    
    // Connect output
    assign count = current_count;
    
endmodule

// Counter control logic module
module counter_control (
    input wire load,
    input wire count_en,
    input wire [7:0] load_val,
    input wire [7:0] current_count,
    output reg [7:0] next_count
);
    // Determine next count value based on control signals
    always @(*) begin
        if (load)
            next_count = load_val;
        else if (count_en)
            next_count = current_count + 1'b1;
        else
            next_count = current_count;
    end
endmodule

// Counter register module
module counter_register (
    input wire clk,
    input wire rst,
    input wire [7:0] next_count,
    output reg [7:0] count
);
    // Register to store the count value
    always @(posedge clk) begin
        if (rst)
            count <= 8'h00;
        else
            count <= next_count;
    end
endmodule