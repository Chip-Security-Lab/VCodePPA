//SystemVerilog
module shift_chain_buf #(parameter DW=8, DEPTH=4) (
    input clk, en,
    input serial_in,
    input [DW-1:0] parallel_in,
    input load,
    input rst,
    output serial_out,
    output [DW*DEPTH-1:0] parallel_out
);
    // Pipeline registers
    reg [DW-1:0] shift_reg [0:DEPTH-1];
    
    // Pipeline control signals
    reg load_stage1, load_stage2;
    reg en_stage1, en_stage2;
    
    // Pipeline data registers
    wire [DW-1:0] next_val_stage1;
    reg [DW-1:0] next_val_stage2;
    reg [DW-1:0] next_val_stage3;
    
    // Stage 1: Calculate the next value using the adder
    manchester_carry_adder_pipelined #(.WIDTH(DW)) adder_inst (
        .clk(clk),
        .rst(rst),
        .a(parallel_in),
        .b(8'h01),  // 加1操作作为示例
        .cin(1'b0),
        .sum(next_val_stage1),
        .cout()
    );
    
    // Pipeline control logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            load_stage1 <= 1'b0;
            load_stage2 <= 1'b0;
            en_stage1 <= 1'b0;
            en_stage2 <= 1'b0;
            next_val_stage2 <= {DW{1'b0}};
            next_val_stage3 <= {DW{1'b0}};
        end else begin
            // Control signals pipeline
            load_stage1 <= load;
            load_stage2 <= load_stage1;
            en_stage1 <= en;
            en_stage2 <= en_stage1;
            
            // Data pipeline
            next_val_stage2 <= next_val_stage1;
            next_val_stage3 <= next_val_stage2;
        end
    end
    
    // Shift register operation - pipelined
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            integer i;
            for(i=0; i<DEPTH; i=i+1)
                shift_reg[i] <= 0;
        end else if(en_stage2) begin
            if(load_stage2) begin
                // Apply pipelined operation results with balanced stages
                shift_reg[0] <= next_val_stage3;
                shift_reg[1] <= next_val_stage2;
                shift_reg[2] <= next_val_stage1;
                shift_reg[3] <= next_val_stage2;
            end
            else begin
                // Shift operation is pipelined with the load operation
                shift_reg[3] <= shift_reg[2];
                shift_reg[2] <= shift_reg[1];
                shift_reg[1] <= shift_reg[0];
                shift_reg[0] <= {{(DW-1){1'b0}}, serial_in};
            end
        end
    end
    
    assign serial_out = shift_reg[DEPTH-1][0];
    
    genvar g;
    generate
        for(g=0; g<DEPTH; g=g+1)
            assign parallel_out[g*DW +: DW] = shift_reg[g];
    endgenerate
endmodule

// Pipelined Manchester Carry Adder
module manchester_carry_adder_pipelined #(parameter WIDTH=8) (
    input clk,
    input rst,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output reg [WIDTH-1:0] sum,
    output reg cout
);
    // Stage 1 signals
    wire [WIDTH-1:0] p_stage1; // 传播信号
    wire [WIDTH-1:0] g_stage1; // 生成信号
    reg [WIDTH-1:0] p_reg1;
    reg [WIDTH-1:0] g_reg1;
    reg cin_reg1;
    
    // Stage 2 signals
    wire [WIDTH:0] c_stage2;  // 进位信号
    reg [WIDTH:0] c_reg2;
    reg [WIDTH-1:0] p_reg2;
    
    // Calculate generate and propagate in stage 1
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_pg
            assign p_stage1[i] = a[i] ^ b[i];  // 传播信号
            assign g_stage1[i] = a[i] & b[i];  // 生成信号
        end
    endgenerate
    
    // Stage 1 pipeline registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            p_reg1 <= {WIDTH{1'b0}};
            g_reg1 <= {WIDTH{1'b0}};
            cin_reg1 <= 1'b0;
        end else begin
            p_reg1 <= p_stage1;
            g_reg1 <= g_stage1;
            cin_reg1 <= cin;
        end
    end
    
    // Initial carry for stage 2
    assign c_stage2[0] = cin_reg1;
    
    // Calculate carry chain in stage 2
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_carry
            assign c_stage2[i+1] = g_reg1[i] | (p_reg1[i] & c_stage2[i]);
        end
    endgenerate
    
    // Stage 2 pipeline registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_reg2 <= {(WIDTH+1){1'b0}};
            p_reg2 <= {WIDTH{1'b0}};
        end else begin
            c_reg2 <= c_stage2;
            p_reg2 <= p_reg1;
        end
    end
    
    // Final stage - calculate sum and carry out
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum <= {WIDTH{1'b0}};
            cout <= 1'b0;
        end else begin
            // Generate sum in the final pipeline stage
            for (integer j = 0; j < WIDTH; j = j + 1) begin
                sum[j] <= p_reg2[j] ^ c_reg2[j];
            end
            cout <= c_reg2[WIDTH];
        end
    end
endmodule