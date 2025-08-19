//SystemVerilog

module xor2_3_top (
    input wire clk,
    input wire rst_n,
    // Input interface
    input wire [7:0] A, B,
    input wire valid_in,
    output wire ready_out,
    // Output interface
    output reg [7:0] Y,
    output reg valid_out,
    input wire ready_in
);
    // Internal signals
    wire [3:0] lower_y, upper_y;
    reg [7:0] A_reg, B_reg;
    wire lower_valid_out, upper_valid_out;
    wire lower_ready_in, upper_ready_in;
    wire internal_valid;
    reg processing;
    
    // Control logic for input handshaking
    assign ready_out = !processing || (valid_out && ready_in);
    
    // Internal valid signal
    assign internal_valid = lower_valid_out && upper_valid_out;
    
    // Ready signals for submodules
    assign lower_ready_in = ready_in && upper_valid_out;
    assign upper_ready_in = ready_in && lower_valid_out;
    
    // Input registers and control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= 8'b0;
            B_reg <= 8'b0;
            processing <= 1'b0;
        end
        else if (valid_in && ready_out) begin
            A_reg <= A;
            B_reg <= B;
            processing <= 1'b1;
        end
        else if (valid_out && ready_in) begin
            processing <= 1'b0;
        end
    end
    
    // Output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 8'b0;
            valid_out <= 1'b0;
        end
        else if (internal_valid && ready_in) begin
            Y <= {upper_y, lower_y};
            valid_out <= 1'b1;
        end
        else if (valid_out && ready_in) begin
            valid_out <= 1'b0;
        end
    end
    
    // Instantiate lower 4-bit submodule
    xor2_3_4bit lower_nibble (
        .clk(clk),
        .rst_n(rst_n),
        .A_in(A_reg[3:0]),
        .B_in(B_reg[3:0]),
        .valid_in(processing),
        .ready_out(),  // Not connected as we use processing flag
        .Y_out(lower_y),
        .valid_out(lower_valid_out),
        .ready_in(lower_ready_in)
    );
    
    // Instantiate upper 4-bit submodule
    xor2_3_4bit upper_nibble (
        .clk(clk),
        .rst_n(rst_n),
        .A_in(A_reg[7:4]),
        .B_in(B_reg[7:4]),
        .valid_in(processing),
        .ready_out(),  // Not connected as we use processing flag
        .Y_out(upper_y),
        .valid_out(upper_valid_out),
        .ready_in(upper_ready_in)
    );
    
endmodule

module xor2_3_4bit (
    input wire clk,
    input wire rst_n,
    // Input interface
    input wire [3:0] A_in,
    input wire [3:0] B_in,
    input wire valid_in,
    output wire ready_out,
    // Output interface
    output reg [3:0] Y_out,
    output reg valid_out,
    input wire ready_in
);
    // Internal signals
    wire [1:0] lower_result, upper_result;
    reg [3:0] A_reg, B_reg;
    wire lower_valid_out, upper_valid_out;
    wire lower_ready_in, upper_ready_in;
    wire internal_valid;
    reg processing;
    
    // Control logic for input handshaking
    assign ready_out = !processing || (valid_out && ready_in);
    
    // Internal valid signal
    assign internal_valid = lower_valid_out && upper_valid_out;
    
    // Ready signals for submodules
    assign lower_ready_in = ready_in && upper_valid_out;
    assign upper_ready_in = ready_in && lower_valid_out;
    
    // Input registers and control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= 4'b0;
            B_reg <= 4'b0;
            processing <= 1'b0;
        end
        else if (valid_in && ready_out) begin
            A_reg <= A_in;
            B_reg <= B_in;
            processing <= 1'b1;
        end
        else if (valid_out && ready_in) begin
            processing <= 1'b0;
        end
    end
    
    // Output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y_out <= 4'b0;
            valid_out <= 1'b0;
        end
        else if (internal_valid && ready_in) begin
            Y_out <= {upper_result, lower_result};
            valid_out <= 1'b1;
        end
        else if (valid_out && ready_in) begin
            valid_out <= 1'b0;
        end
    end
    
    // Instantiate lower 2-bit submodule
    xor2_3_2bit lower_bits (
        .clk(clk),
        .rst_n(rst_n),
        .A_in(A_reg[1:0]),
        .B_in(B_reg[1:0]),
        .valid_in(processing),
        .ready_out(),  // Not connected as we use processing flag
        .Y_out(lower_result),
        .valid_out(lower_valid_out),
        .ready_in(lower_ready_in)
    );
    
    // Instantiate upper 2-bit submodule
    xor2_3_2bit upper_bits (
        .clk(clk),
        .rst_n(rst_n),
        .A_in(A_reg[3:2]),
        .B_in(B_reg[3:2]),
        .valid_in(processing),
        .ready_out(),  // Not connected as we use processing flag
        .Y_out(upper_result),
        .valid_out(upper_valid_out),
        .ready_in(upper_ready_in)
    );
    
endmodule

module xor2_3_2bit (
    input wire clk,
    input wire rst_n,
    // Input interface
    input wire [1:0] A_in,
    input wire [1:0] B_in,
    input wire valid_in,
    output wire ready_out,
    // Output interface
    output reg [1:0] Y_out,
    output reg valid_out,
    input wire ready_in
);
    // Internal signals
    wire bit0_result, bit1_result;
    reg [1:0] A_reg, B_reg;
    wire bit0_valid_out, bit1_valid_out;
    wire bit0_ready_in, bit1_ready_in;
    wire internal_valid;
    reg processing;
    
    // Control logic for input handshaking
    assign ready_out = !processing || (valid_out && ready_in);
    
    // Internal valid signal
    assign internal_valid = bit0_valid_out && bit1_valid_out;
    
    // Ready signals for submodules
    assign bit0_ready_in = ready_in && bit1_valid_out;
    assign bit1_ready_in = ready_in && bit0_valid_out;
    
    // Input registers and control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_reg <= 2'b0;
            B_reg <= 2'b0;
            processing <= 1'b0;
        end
        else if (valid_in && ready_out) begin
            A_reg <= A_in;
            B_reg <= B_in;
            processing <= 1'b1;
        end
        else if (valid_out && ready_in) begin
            processing <= 1'b0;
        end
    end
    
    // Output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y_out <= 2'b0;
            valid_out <= 1'b0;
        end
        else if (internal_valid && ready_in) begin
            Y_out <= {bit1_result, bit0_result};
            valid_out <= 1'b1;
        end
        else if (valid_out && ready_in) begin
            valid_out <= 1'b0;
        end
    end
    
    // Instantiate bit 0 submodule
    xor2_3_1bit bit0 (
        .clk(clk),
        .rst_n(rst_n),
        .a(A_reg[0]),
        .b(B_reg[0]),
        .valid_in(processing),
        .ready_out(),  // Not connected as we use processing flag
        .y(bit0_result),
        .valid_out(bit0_valid_out),
        .ready_in(bit0_ready_in)
    );
    
    // Instantiate bit 1 submodule
    xor2_3_1bit bit1 (
        .clk(clk),
        .rst_n(rst_n),
        .a(A_reg[1]),
        .b(B_reg[1]),
        .valid_in(processing),
        .ready_out(),  // Not connected as we use processing flag
        .y(bit1_result),
        .valid_out(bit1_valid_out),
        .ready_in(bit1_ready_in)
    );
    
endmodule

module xor2_3_1bit (
    input wire clk,
    input wire rst_n,
    // Input interface
    input wire a,
    input wire b,
    input wire valid_in,
    output wire ready_out,
    // Output interface
    output reg y,
    output reg valid_out,
    input wire ready_in
);
    // Internal signals
    reg a_reg, b_reg;
    reg processing;
    wire xor_result;
    
    // XOR operation
    assign xor_result = a_reg ^ b_reg;
    
    // Control logic for input handshaking
    assign ready_out = !processing || (valid_out && ready_in);
    
    // Input registers and control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 1'b0;
            b_reg <= 1'b0;
            processing <= 1'b0;
        end
        else if (valid_in && ready_out) begin
            a_reg <= a;
            b_reg <= b;
            processing <= 1'b1;
        end
        else if (valid_out && ready_in) begin
            processing <= 1'b0;
        end
    end
    
    // Output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
            valid_out <= 1'b0;
        end
        else if (processing && !valid_out) begin
            y <= xor_result;
            valid_out <= 1'b1;
        end
        else if (valid_out && ready_in) begin
            valid_out <= 1'b0;
        end
    end
    
endmodule