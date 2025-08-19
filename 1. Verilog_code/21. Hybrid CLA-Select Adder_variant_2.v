module hybrid_adder_axi_stream(
    input wire aclk,
    input wire aresetn,
    
    // AXI-Stream Slave Interface
    input wire [7:0] s_axis_a_tdata,
    input wire s_axis_a_tvalid,
    output wire s_axis_a_tready,
    
    input wire [7:0] s_axis_b_tdata, 
    input wire s_axis_b_tvalid,
    output wire s_axis_b_tready,
    
    input wire s_axis_cin_tdata,
    input wire s_axis_cin_tvalid,
    output wire s_axis_cin_tready,
    
    // AXI-Stream Master Interface
    output wire [8:0] m_axis_result_tdata,
    output wire m_axis_result_tvalid,
    input wire m_axis_result_tready
);

    // Internal registers
    reg [7:0] a_reg, b_reg;
    reg cin_reg;
    reg [7:0] sum_reg;
    reg cout_reg;
    reg result_valid;
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    
    // State machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (s_axis_a_tvalid && s_axis_b_tvalid && s_axis_cin_tvalid)
                    next_state = CALC;
                else
                    next_state = IDLE;
            end
            
            CALC: begin
                next_state = DONE;
            end
            
            DONE: begin
                if (m_axis_result_tready)
                    next_state = IDLE;
                else
                    next_state = DONE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Data path
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            cin_reg <= 1'b0;
            sum_reg <= 8'b0;
            cout_reg <= 1'b0;
            result_valid <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (s_axis_a_tvalid && s_axis_b_tvalid && s_axis_cin_tvalid) begin
                        a_reg <= s_axis_a_tdata;
                        b_reg <= s_axis_b_tdata;
                        cin_reg <= s_axis_cin_tdata;
                        result_valid <= 1'b0;
                    end
                end
                
                CALC: begin
                    {cout_reg, sum_reg} <= a_reg + b_reg + cin_reg;
                    result_valid <= 1'b1;
                end
                
                DONE: begin
                    if (m_axis_result_tready)
                        result_valid <= 1'b0;
                end
            endcase
        end
    end
    
    // Output assignments
    assign s_axis_a_tready = (state == IDLE);
    assign s_axis_b_tready = (state == IDLE);
    assign s_axis_cin_tready = (state == IDLE);
    
    assign m_axis_result_tdata = {cout_reg, sum_reg};
    assign m_axis_result_tvalid = result_valid;
    
    // Instantiate hybrid adder for calculation
    wire [7:0] sum;
    wire cout;
    
    hybrid_adder adder_inst(
        .a(a_reg),
        .b(b_reg),
        .cin(cin_reg),
        .sum(sum),
        .cout(cout)
    );

endmodule

// Keep original modules unchanged
module hybrid_adder(
    input [7:0] a, b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [3:0] sum_low, sum_high;
    wire carry_mid;
    
    cla_adder low(a[3:0], b[3:0], cin, sum_low, carry_mid);
    carry_select_adder high(a[7:4], b[7:4], carry_mid, sum_high, cout);
    
    assign sum = {sum_high, sum_low};
endmodule

module ripple_carry_adder(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [4:0] c;
    
    assign c[0] = cin;
    
    full_adder fa0(a[0], b[0], c[0], sum[0], c[1]);
    full_adder fa1(a[1], b[1], c[1], sum[1], c[2]);
    full_adder fa2(a[2], b[2], c[2], sum[2], c[3]);
    full_adder fa3(a[3], b[3], c[3], sum[3], c[4]);
    
    assign cout = c[4];
endmodule

module carry_select_adder(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] sum0, sum1;
    wire cout0, cout1;
    
    ripple_carry_adder rca0(a, b, 1'b0, sum0, cout0);
    ripple_carry_adder rca1(a, b, 1'b1, sum1, cout1);
    
    assign sum = cin ? sum1 : sum0;
    assign cout = cin ? cout1 : cout0;
endmodule

module full_adder(
    input a, b, cin,
    output sum, cout
);
    wire p, g;
    
    assign p = a ^ b;
    assign g = a & b;
    assign sum = p ^ cin;
    assign cout = g | (p & cin);
endmodule

module cla_adder(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] p, g;
    wire [4:0] c;
    
    assign p = a ^ b;
    assign g = a & b;
    
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    assign sum = p ^ c[3:0];
    assign cout = c[4];
endmodule