module xor_task_based(input a, b, output y);
    reg temp;
    
    task automatic do_xor;
        input x, y;
        output z;
        begin
            z = x ^ y;
        end
    endtask
    
    always @(*) begin
        do_xor(a, b, temp);
    end
    assign y = temp;
endmodule